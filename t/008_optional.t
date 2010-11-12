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
like $@, qr/Missing parameter: 'foo'/, 'missing parameters';
like $@, qr/Missing parameter: 'bar'/, 'missing parameters';

eval {
    $v->validate(baz => 1);
};
like $@, qr/Missing parameter: 'foo'/, 'missing parameters';
like $@, qr/Missing parameter: 'bar'/, 'missing parameters';

eval {
    $v->validate(foo => 1);
};
like $@, qr/Missing parameter: 'bar'/, 'missing parameters';
unlike $@, qr/Missing parameter: 'foo'/, 'missing parameters';

eval {
    $v->validate(bar => 1);
};
like $@, qr/Missing parameter: 'foo'/, 'missing parameters';
unlike $@, qr/Missing parameter: 'bar'/, 'missing parameters';

done_testing;
