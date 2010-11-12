#!perl -w
use strict;
use Test::More;

use Data::Validator;

my $v = Data::Validator->new(
    foo => { },
    bar => { },
    baz => { optional => 1 }
);
isa_ok $v, 'Data::Validator';

my $args = $v->validate({ foo => 1, bar => 2 });
is_deeply $args, { foo => 1, bar => 2 };

$args = $v->validate({ foo => 1, bar => 2, baz => 3 });
is_deeply $args, { foo => 1, bar => 2, baz => 3 };

note 'failing cases';

eval {
    $v->validate();
};
like $@, qr/Missing parameters: 'bar' and 'foo' at/, 'missing parameters';

eval {
    $v->validate(baz => 1);
};
like $@, qr/Missing parameters: 'bar' and 'foo' at/, 'missing parameters';

eval {
    $v->validate(foo => 1);
};
like $@, qr/Missing parameters: 'bar' at/, 'missing parameters';

eval {
    $v->validate(bar => 1);
};
like $@, qr/Missing parameters: 'foo' at/, 'missing parameters';

done_testing;
