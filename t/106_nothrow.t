#!perl -w
use strict;
use Test::More;

use Data::Validator;

my $v = Data::Validator->new(
    foo => 'Num',
)->with('NoThrow');
isa_ok $v, 'Data::Validator';

my $args = $v->validate(foo => 42);
is_deeply $args, { foo => 42 };
ok !$v->has_errors;
$v->clear_errors();

$args = $v->validate();
is_deeply $args, { };
ok $v->has_errors();
is scalar(@{$v->errors}), 1;
my $e = $v->errors->[0];
is $e->{type}, 'MissingParameter', 'MissingParameter';
is $e->{name}, 'foo';
like $e->{message}, qr/Missing parameter: 'foo'/;
$v->clear_errors();


$args = $v->validate(foo => 'bar');
is_deeply $args, { foo => 'bar' };
ok $v->has_errors();
is scalar(@{$v->errors}), 1;
$e = $v->errors->[0];
is $e->{type}, 'InvalidValue', 'InvalidValue';
is $e->{name}, 'foo';
like $e->{message}, qr/Validation failed/;
$v->clear_errors();

$args = $v->validate(foo => 42, bar => 10);
is_deeply $args, { foo => 42, bar => 10 };
ok $v->has_errors();
is scalar(@{$v->errors}), 1;
$e = $v->errors->[0];
is $e->{type}, 'UnknownParameter', 'UnknownParameter';
is $e->{name}, 'bar';
like $e->{message}, qr/Unknown parameter: 'bar'/;
$v->clear_errors();

$args = $v->validate(foo => 'bar', baz => 10);
is_deeply $args, { foo => 'bar', baz => 10 };
ok $v->has_errors();
is scalar(@{$v->errors}), 2;
$e = $v->errors->[0];
is $e->{type}, 'InvalidValue', 'InvalidValue';
is $e->{name}, 'foo';
$e = $v->errors->[1];
is $e->{type}, 'UnknownParameter', 'UnknownParameter';
is $e->{name}, 'baz';
$v->clear_errors();

done_testing;
