#!perl -w
use strict;
use Test::More;

use Data::Validator;

my $v = Data::Validator->new(
    foo => { isa => 'Num', default => 99 },
);
isa_ok $v, 'Data::Validator';

my $args = $v->validate({ foo => 42 });
is_deeply $args, { foo => 42 };

$args = $v->validate(+{});
is_deeply $args, { foo => 99 };

$args = $v->validate();
is_deeply $args, { foo => 99 };

done_testing;
