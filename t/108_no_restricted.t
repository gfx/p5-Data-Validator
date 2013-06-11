#!perl -w
use strict;
use Test::More;

use Data::Validator;

my $v = Data::Validator->new(
    foo => 'Num',
)->with('NoRestricted');
isa_ok $v, 'Data::Validator';

my $args = $v->validate({ foo => 42 });

$args->{bar}++;

is_deeply $args, { foo => 42, bar => 1 };


done_testing;
