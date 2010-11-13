#!perl -w
use strict;
use Test::More;
use Data::Validator;

my $v = Data::Validator->new(
    uri        => { xor => [qw(schema host path_query)] },

    schema     => { default => 'http' },
    host       => { default => '127.0.0.1' },
    path_query => { default => '/' },

    method     => { default => 'GET' },
);

note( $v->dump );

my $args;

note 'success cases';

$args = $v->validate({ uri => 'https://example.com/' });
is_deeply $args, {
    uri        => 'https://example.com/',
    method     => 'GET',
};

$args = $v->validate({
    schema     => 'https',
    host       => 'example.com',
    path_query => '/index.html',
});
is_deeply $args, {
    schema     => 'https',
    host       => 'example.com',
    path_query => '/index.html',
    method     => 'GET',
};

$args = $v->validate({
    host => 'example.com',
});
is_deeply $args, {
    schema     => 'http',
    host       => 'example.com',
    path_query => '/',
    method     => 'GET',
};

$args = $v->validate();
is_deeply $args, {
    schema     => 'http',
    host       => '127.0.0.1',
    path_query => '/',
    method     => 'GET',
};

note 'failure cases';

eval {
    $v->validate({ uri => 'foo', schema => 'http' });
};
like $@, qr/Exclusive parameters passed together: 'uri' v.s. 'schema'/;

eval {
    $v->validate(uri => 'foo', schema => 'http', host => 'example.com');
};
like $@, qr/Exclusive parameters passed together: 'uri' v.s. 'host'/;
like $@, qr/Exclusive parameters passed together: 'uri' v.s. 'schema'/;

note 'case without defaults';
$v = Data::Validator->new(
    uri        => { xor => [qw(schema host path_query)] },

    schema     => { default => 'http' },
    host       => { },
    path_query => { default => '/' },

    method     => { default => 'GET' },
);

$args = $v->validate(
    uri => 'http://example.com/',
);
is_deeply $args, {
    uri        => 'http://example.com/',
    method     => 'GET',
};

$args = $v->validate(
    host => 'example.com',
);
is_deeply $args, {
    schema     => 'http',
    host       => 'example.com',
    path_query => '/',
    method     => 'GET',
};

eval {
    $v->validate();
};
like $@, qr/Missing parameter: 'host' \(or 'uri'\)/;

done_testing;

