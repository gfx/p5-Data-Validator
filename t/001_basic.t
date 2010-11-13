#!perl -w
use strict;
use Test::More;

use Data::Validator;

my $v = Data::Validator->new(
    foo => 'Num',
);
isa_ok $v, 'Data::Validator';
ok $v->find_rule('foo');
is $v->find_rule('foo')->{name}, 'foo';
ok !defined($v->find_rule('bar'));


my $args = $v->validate({ foo => 42 });
is_deeply $args, { foo => 42 };

$args = $v->validate({ foo => 3.14 });
is_deeply $args, { foo => 3.14 };

$args = $v->validate( foo => 3.14 );
is_deeply $args, { foo => 3.14 };

note 'failing cases';

eval {
    $v->validate();
};
like $@, qr/Missing parameter: 'foo'/, 'missing parameters';

eval {
    $v->validate({foo => 'bar'});
};
like $@, qr/Validation failed for 'Num' with value bar/, 'validation falure';

eval {
    $v->validate({ foo => 0, baz => 42, qux => 100 });
};
like $@, qr/Unknown parameter: 'baz'/;
like $@, qr/Unknown parameter: 'qux'/;

done_testing;
