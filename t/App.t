use strict;
use warnings;
use lib qw(./lib);
use Test::More tests => 24;

use Dancer ':syntax';
use Dancer::Test;
use Path::Tiny;
use Clone qw(clone);
use Catmandu;

Catmandu->load(path(__FILE__)->parent->parent);

{
    # mimic dancer config loading
    my $config = clone(Catmandu->config->{dancer});
    my $env = setting('environment');
    my $env_config = (delete($config->{_environments}) || {})->{$env} || {};
    my %mergeable = (plugins => 1, handlers => 1);
    for my $key (keys %$env_config) {
        if ($mergeable{$key}) {
            $config->{$key}{$_} = $env_config->{$key}{$_} for keys %{$env_config->{$key}};
        } else {
            $config->{$key} = $env_config->{$key};
        }
    }
    $config->{apphandler} = 'PSGI';
    $config->{appdir} //= Catmandu->root;
    set %$config;
    Dancer::Config->load;
    load_app 'App';
}

use App::Helper;

h->config->{default_lang} = 'en';

route_exists          [GET => '/'], "GET /publications is handled";
response_status_is    [GET => '/'], 200, 'GET / status is ok';
response_content_like [GET => '/'], qr/Search Publications/,
    "content looks good for /";

route_exists       [GET => '/publication'], "GET /publications is handled";
response_status_is [GET => '/publication'], 200,
    'GET /publication status is ok';
response_content_like [GET => '/publication'], qr/Publications/,
    "content looks good for /publication";

route_exists          [GET => '/person'], "GET /person is handled";
response_status_is    [GET => '/person'], 200, 'GET /person status is ok';
response_content_like [GET => '/person'], qr/Authors/,
    "content looks good for /person";

route_exists          [GET => '/data'], "GET /data is handled";
response_status_is    [GET => '/data'], 200, 'GET /data status is ok';
response_content_like [GET => '/data'], qr/Data Publications/,
    "content looks good for /data";

route_exists          [GET => '/contact'], "GET /contact is handled";
response_status_is    [GET => '/contact'], 200, 'GET /contact status is ok';
response_content_like [GET => '/contact'], qr/Contact/,
    "content looks good for /contact";

route_exists          [GET => '/oai'], "GET /oai is handled";
response_status_is    [GET => '/oai'], 200, 'GET /oai status is ok';
response_content_like [GET => '/oai'], qr/OAI-PMH/,
    "content looks good for /oai";

route_exists          [GET => '/sru'], "GET /sru is handled";
response_status_is    [GET => '/sru'], 200, 'GET /sru status is ok';
response_content_like [GET => '/sru'], qr/explainResponse/,
    "content looks good for /sru";

route_exists          [GET => '/login'], "GET /login is handled";
response_status_is    [GET => '/login'], 200, 'GET /login status is ok';
response_content_like [GET => '/login'], qr/Login/,
    "content looks good for /login";
