#!perl -w
use strict;
use Test::More;

use Data::Validator;

my $v = Data::Validator->new(
    foo => 'Num',
    bar => 'Num',
)->with('Sequenced');
isa_ok $v, 'Data::Validator';

my $args = $v->validate({ foo => 42, bar => 1 });
is_deeply $args, { foo => 42, bar => 1 };

$args = $v->validate(3.14, 2.0);
is_deeply $args, { foo => 3.14, bar => 2.0 };

$args = $v->validate(3.14, { bar => 10 });
is_deeply $args, { foo => 3.14, bar => 10 };

note 'failing cases';

eval {
    $v->validate({});
};
like $@, qr/Missing parameter: 'foo'/, 'missing parameters';
like $@, qr/Missing parameter: 'bar'/, 'missing parameters';

eval {
    $v->validate();
};
like $@, qr/Missing parameter: 'foo'/, 'missing parameters';
like $@, qr/Missing parameter: 'bar'/, 'missing parameters';

eval {
    $v->validate({foo => 'bar', bar => 1});
};
like $@, qr/Validation failed for 'Num' with value bar/, 'validation falure';

eval {
    $v->validate('bar', 1);
};
like $@, qr/Validation failed for 'Num' with value bar/, 'validation falure';

eval {
    $v->validate(42, 'bar');
};
like $@, qr/Validation failed for 'Num' with value bar/, 'validation falure';

eval {
    $v->validate(1, 2, 3, 4);
};
like $@, qr/Unknown parameter:/;

done_testing;
