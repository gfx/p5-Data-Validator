#!perl -w
use strict;
use Test::More;

use Data::Validator;

my $v = Data::Validator->new(
    foo => 'Num',
);
isa_ok $v, 'Data::Validator';

my $args = $v->validate({ foo => 42 });
is_deeply $args, { foo => 42 };

eval {
    my $a = $args->{bar};
};
like $@, qr/bar/;

eval {
    $args->{foo}++;
};
is $@, '';
is $args->{foo}, 43;

done_testing;
