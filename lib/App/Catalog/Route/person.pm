package App::Catalog::Route::person;

use Catmandu::Sane;
use Catmandu::Util qw(:array);
use Dancer ':syntax';

use App::Catalog::Helper;
use App::Catalog::Controller::Admin qw/:person/;

prefix '/person' => sub {

    get '/preferences' => sub {

        my $person = h->getPerson( session('personNumber') );
        my $style;
        my $sort;
        if (    $person->{stylePreference}
            and $person->{stylePreference} =~ /(\w{1,})\.(\w{1,})/ )
        {
            if ( array_includes( h->config->{lists}->{styles}, $1 ) ) {
                $style = $1 unless $1 eq "pub";
            }
            $sort = $2;
        }
        elsif ( $person->{stylePreference}
            and $person->{stylePreference} !~ /\w{1,}\.\w{1,}/ )
        {
            if (array_includes(
                    h->config->{lists}->{styles},
                    $person->{stylePreference}
                )
                )
            {
                $style = $person->{stylePreference}
                    unless $person->{stylePreference} eq "pub";
            }
        }

        if ( $person->{sortPreference} ) {
            $sort = $person->{sortPreference};
        }

        $person->{stylePreference}
            = params->{style}
            || $style
            || h->config->{store}->{default_fd_style};
        $person->{sortPreference} = params->{'sort'} || $sort || "desc";

        h->authority_user->add($person);

        redirect '/myPUB';
    };

    post '/author_id' => sub {

        my $person     = h->authority_user->get( params->{_id} );
        my @identifier = keys h->config->{lists}->{author_id};

        map { $person->{$_} = params->{$_} ? params->{$_} : "" } @identifier;

        my $bag = h->authority_user->add($person);

        redirect '/myPUB';

    };

    post '/affiliation' => sub {

        my $p = params;
        $p = h->nested_params($p);
        my $person = edit_person( session('personNumber') );
        $person->{department} = $p->{department};
        update_person($person);

        redirect '/myPUB';

    };

};

1;
