use Catmandu::Sane;
use Path::Tiny;
use lib path(__FILE__)->parent->parent->child('lib')->stringify;
use LibreCat load => (layer_paths => [qw(t/layer)]);
use Test::More;

# hooks

{
    my $hook = LibreCat->hook('eat');
    is scalar(@{$hook->before_fixes}), 2;
    is scalar(@{$hook->after_fixes}),  1;
    my $data = {};
    $hook->fix_before($data);
    is_deeply($data, {peckish => 1, hungry => 1});
    $hook->fix_after($data);
    is_deeply($data, {satisfied => 1});
}

{
    my $hook = LibreCat->hook('idontexist');

    is scalar(@{$hook->before_fixes}), 0;
    is scalar(@{$hook->after_fixes}),  0;

    my $data = {foo => 'bar'};
    $hook->fix_before($data);
    is_deeply($data, {foo => 'bar'});
}

done_testing;
