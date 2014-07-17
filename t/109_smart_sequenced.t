#!perl -w
use strict;
use Test::More;

use Data::Validator;

my $v = Data::Validator->new(
    foo => 'Num',
    bar => 'Num',
)->with('SmartSequenced');

isa_ok $v, 'Data::Validator';

my $args = $v->validate(42, 1);
is_deeply $args, { foo => 42, bar => 1 };

$args = $v->validate(3.14, 2.0);
is_deeply $args, { foo => 3.14, bar => 2.0 };


note 'differ from StrictSequenced';

eval {
    $v->validate({});
};
like $@, qr/Missing parameter: 'foo'/, 'missing parameters';    # differ from StrictSequenced
like $@, qr/Missing parameter: 'bar'/, 'missing parameters';

eval {
    $v->validate();
};
like $@, qr/Missing parameter: 'foo'/, 'missing parameters';
like $@, qr/Missing parameter: 'bar'/, 'missing parameters';

eval {
    $v->validate({foo => 'bar', bar => 1});
};
like $@, qr/Invalid value for 'foo': Validation failed for 'Num' with value/, 'missing parameters';
unlike $@, qr/Missing parameter: 'bar'/, 'found parameters';    # differ from StrictSequenced

eval {
    $v->validate('bar', 1);
};
like $@, qr/Validation failed for 'Num' with value bar/, 'validation falure';

eval {
    $v->validate(42, 'bar');
};
like $@, qr/Validation failed for 'Num' with value bar/, 'validation falure';

$v->validate(3.14, { bar => 10 });    # differ from StrictSequenced

eval {
    $v->validate(1, 2, 3, 4);
};
like $@, qr/Unknown parameter:/;


note 'differ from Sequenced';

$v = Data::Validator->new(
    foo => 'Num',
    bar => 'HashRef',
)->with('Sequenced');

$args = $v->validate({ foo => 42, bar => { key => 'value' } });
is_deeply $args, { foo => 42, bar => { key => 'value' } };

eval {
    $v->validate(42, { key => 'value' });
};
like $@, qr/Missing parameter: 'bar'/, 'missing parameters';
like $@, qr/Unknown parameter: 'key'/, 'unexpected expansion of last hashref';

$v = Data::Validator->new(
    foo => 'Num',
    bar => 'HashRef',
)->with('SmartSequenced');

$args = $v->validate({ foo => 42, bar => { key => 'value' } });
is_deeply $args, { foo => 42, bar => { key => 'value' } }, 'same as Sequenced';

$args = $v->validate(42, { key => 'value' });    # differ from Sequenced
is_deeply $args, { foo => 42, bar => { key => 'value' } }, 'deals with last hashref';


note 'SmartSequenced';

$v = Data::Validator->new(
    foo => 'Num',
    bar => { isa => 'Num', optional => 1 },
    baz => { isa => 'Num', default => 2.72 },
)->with('SmartSequenced');

$args = $v->validate(42, { bar => 1, baz => 2.718 });
is_deeply $args, { foo => 42, bar => 1, baz => 2.718 }, 'required as sequenced, the others as hashref';

$args = $v->validate(42);
is_deeply $args, { foo => 42, baz => 2.72 }, 'required as sequenced';

$args = $v->validate({ foo => 42 });
is_deeply $args, { foo => 42, baz => 2.72 }, 'required as hashref';

$args = $v->validate({ foo => 3.14, bar => 2.0, baz => 2.718 });
is_deeply $args, { foo => 3.14, bar => 2.0, baz => 2.718 }, 'all as hashref';

note 'SmartSequenced - the last optional hashref';
$v = Data::Validator->new(
    foo => 'Num',
    bar => { isa => 'HashRef', optional => 1 },
)->with('SmartSequenced');
my $expected = { foo => 3, bar => { val => 3 } };
is_deeply $v->validate( 3, { bar => { val => 3 } } ), $expected, 'mixed style';
is_deeply $v->validate( 3, { val => 3 } ), $expected, 'sequenced style';
is_deeply $v->validate( { foo => 3, bar => { val => 3 } } ), $expected, 'named style';

done_testing;
