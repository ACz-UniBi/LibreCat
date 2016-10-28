use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use App::Cmd::Tester;
use LibreCat::CLI;
use Path::Tiny;
use lib path(__FILE__)->parent->parent->child('lib')->stringify;
use LibreCat load => (layer_paths => [qw(t/layer)]);
use Data::Dumper;

my $pkg;
BEGIN {
    unless (-d 't/tmp/sitemap') {
        mkdir 't/tmp/sitemap';
    }
    unlink glob "'t/tmp/sitemap/*.*'";

    $pkg = 'LibreCat::Cmd::sitemap';
    use_ok $pkg;
}

require_ok $pkg;

# add some data
{
    Catmandu->store('backup')->bag('publication')->delete_all;
    Catmandu->store('search')->bag('publication')->delete_all;
    my $result = test_app(qq|LibreCat::CLI| =>
            ['publication', 'add', 't/records/valid-publication.yml']);
}

{
    my $result = test_app(qq|LibreCat::CLI| => ['sitemap']);
    ok $result->error, 'ok threw an exception';
}

{
    my $result = test_app(qq|LibreCat::CLI| =>
        ['sitemap', '--dir', 't/tmp/sitemap']);

    ok !$result->error, 'ok threw no exception';

    ok !$result->stdout, 'silent';

    ok -f 't/tmp/sitemap/siteindex.xml', 'index site exists';
    ok -f 't/tmp/sitemap/sitemap-00001.xml', 'first sitemap exists';
}

END {
    rmdir 't/tmp/sitemap'
}

done_testing;
