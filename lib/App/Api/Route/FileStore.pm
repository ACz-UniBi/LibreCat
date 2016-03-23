package App::Api::Route::FileStore;

use Catmandu::Sane;
use Dancer ':syntax';
use Dancer::Plugin::Auth::Tiny;
use Dancer::Plugin::StreamData;
use App::Helper;
use IO::File;

Dancer::Plugin::Auth::Tiny->extend(
    role => sub {
        my ($role, $coderef) = @_;
        return sub {
            if ($role eq 'api_access' && ip_match(request->address)) {
                goto $coderef;
            }
            elsif ( session->{role} && $role eq session->{role} ) {
                goto $coderef;
            }
            else {
                return do_error('NOT_ALLOWED','access denied',404);
            }
        }
    }
);

set serializer => 'JSON';

sub ip_match {
    my $ip = shift;
    my $access    = h->config->{filestore_api}->{access} // {};
    my $ip_ranges = $access->{ip_ranges} // [];

    for my $range (@$ip_ranges) {
        $range =~ s{\*}{\\w+}g;
        return 1 if ($ip =~ /^$range$/);
    } 

    return 0;
}

sub file_store {
    my $file_store = h->config->{filestore}->{package};
    my $file_opts  = h->config->{filestore}->{options} // {};

    my $pkg = Catmandu::Util::require_package($file_store,'LibreCat::FileStore');
    $pkg->new(%$file_opts);
}

sub do_error {
    my ($code,$msg,$http_code) = @_;
    $http_code = 500 unless defined $http_code;
    send_error({ code => , $code , error => $msg },$http_code);
}

prefix '/librecat/api' => sub {
	get '/filestore' => needs role => 'api_access' => sub {
        my $gen = file_store()->list;

        content_type 'text/plain';

        return stream_data($gen, sub {
            my ($data,$writer) = @_;

            while (my $key = $data->()) {
                $writer->write("$key\n");
            }

            $writer->close();
        });
    };

    get '/filestore/:key' => needs role => 'api_access' => sub {
        my $key = param('key');
        my $container = file_store()->get($key);

        content_type 'application/json';

        if (defined $container) {
            my $doc = {
                key      => $container->key ,
                created  => $container->created ,
                modified => $container->modified ,
            };

            my @files = $container->list;

            for my $file (@files) {
                my $key      = $file->key;
                my $size     = $file->size;
                my $md5      = $file->md5;
                my $modified = $file->modified;

                push @{$doc->{files}} , {
                    key  => $key ,
                    size => $size ,
                    md5  => $md5 ,
                    modified => $modified 
                };
            }

            return $doc;
        }
        else {
            return do_error('NOT_FOUND','no such container',404);
        }
    };

    get '/filestore/:key/:filename' => needs role => 'api_access' => sub {
        my $key       = param('key');
        my $filename  = param('filename');

        my $container = file_store()->get($key);

        if (defined $container) {
            
            my $file = $container->get($filename);

            if (defined $file) {
                my $io = $file->fh;

                return stream_data($io, sub {
                        my ($data,$writer) = @_;

                        my $buffer_size = h->config->{filestore_api}->{buffer_size} // 1024;

                        while (! $data->eof) {
                            my $buffer;
                            my $len = $data->read($buffer,$buffer_size);
                            $writer->write($buffer);
                        }

                        $writer->close();
                        $data->close();
                });
            }
            else {
                return do_error('NOT_FOUND','no such file',404);
            }
        }
        else {
            return do_error('NOT_FOUND','no such container',404);
        }
    };

    del '/filestore/:key' => needs role => 'api_access' => sub {
        my $key       = param('key');

        content_type 'application/json';
        
        my $container = file_store()->get($key);

        if (defined $container) {
            file_store()->delete($key);
            return { ok => 1 };
        }
        else {
            return do_error('NOT_FOUND','no such container',404);
        }
    };

    del '/filestore/:key/:filename' => needs role => 'api_access' => sub {
        my $key       = param('key');
        my $filename  = param('filename');

        content_type 'application/json';

        my $container = file_store()->get($key);

        if (defined $container) {
            
            my $file = $container->get($filename);

            if (defined $file) {
                $container->delete($filename);
                $container->commit;

                return { ok => 1 };
            }
            else {
                return do_error('NOT_FOUND','no such file',404);
            }
        }
        else {
            return do_error('NOT_FOUND','no such container',404);
        }
    };

    post '/filestore/:key' => needs role => 'api_access' => sub {
        my $key       = param('key');

        content_type 'application/json';

        my $container = file_store()->get($key);

        unless ($container) {
            $container = file_store()->add($key);
        }

        if ($container) {
            my $file    = request->upload('file');

            unless ($file) {
                return do_error('ILLEGAL_INPUT','need a file',400);
            }

            $container->add($file->{filename}, IO::File->new($file->{tempname}));

            $container->commit;

            return { ok => 1 };
        }
        else {
            return do_error('SERVER_ERROR','failed to update container',500);
        }
    };
};

1;