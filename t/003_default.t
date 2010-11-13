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

$v = Data::Validator->new(
    foo => { isa => 'Num', default => 99 },
    bar => { isa => 'Num', default => sub {
            my($validator, $rule, $args) = @_;
            return $args->{foo} + 1;
    } },
);
$args = $v->validate();
is_deeply $args, { foo => 99, bar => 100 };

$args = $v->validate(foo => 42);
is_deeply $args, { foo => 42, bar => 43 };

done_testing;
