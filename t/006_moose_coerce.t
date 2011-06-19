#!perl -w
use strict;
use Test::More;
use Test::Requires { 'Moose::Util::TypeConstraints' => 1.19 };

use Data::Validator;

my $MyHash = subtype 'MyHash', as 'HashRef';
coerce $MyHash,
    from 'ArrayRef', via { +{ @{$_} } };

my $v = Data::Validator->new(
    foo => $MyHash,
);
isa_ok $v, 'Data::Validator';

my $args = $v->validate({ foo => { a => 42 } });
is_deeply $args, { foo => { a => 42 } };

$args = $v->validate({ foo => [ a => 42 ] });
is_deeply $args, { foo => { a => 42 } };

note 'failing cases';

eval {
    $v->validate({foo => 'bar'});
};
like $@, qr/Validation failed for 'MyHash'/, 'validation falure';

done_testing;
