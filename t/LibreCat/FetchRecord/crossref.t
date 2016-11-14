use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use LibreCat load => (layer_paths => [qw(t/layer)]);

my $pkg;

BEGIN {
    $pkg = 'LibreCat::FetchRecord::crossref';
    use_ok $pkg;
}

require_ok $pkg;

my $x;

lives_ok { $x = $pkg->new()} 'lives_ok';

can_ok $pkg, $_ for qw(fetch);

SKIP: {

    unless ($ENV{NETWORK_TEST}) {
        skip("No network. Set NETWORK_TEST to run these tests.", 5);
    }

    my @dois =("doi:10.1002/0470841559.ch1", "http://doi.org/10.1002/0470841559.ch1");
    for (@dois) {
        my $pub = $x->fetch($_);

        ok $pub , 'got a publication for ' . $_;

        is $pub->{title} , 'Network Concepts' , 'got a title';
        is $pub->{type} , 'book_chapter', 'type == book_chapter';
    }
}

done_testing;
