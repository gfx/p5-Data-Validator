#!perl -w
use strict;
use Test::More;

use Data::Validator;

my $v = Data::Validator->new(
    foo => 'Num',
)->with('Sequenced');
isa_ok $v, 'Data::Validator';

my $args = $v->validate({ foo => 42 });
is_deeply $args, { foo => 42 };

$args = $v->validate({ foo => 3.14 });
is_deeply $args, { foo => 3.14 };

$args = $v->validate(3.14);
is_deeply $args, { foo => 3.14 };

note 'failing cases';

eval {
    $v->validate({});
};
like $@, qr/Missing parameters: 'foo' at/, 'missing parameters';

eval {
    $v->validate();
};
like $@, qr/Missing parameters: 'foo' at/, 'missing parameters';

eval {
    $v->validate({foo => 'bar'});
};
like $@, qr/Validation failed for 'Num' with value bar/, 'validation falure';

eval {
    $v->validate('bar');
};
like $@, qr/Validation failed for 'Num' with value bar/, 'validation falure';

done_testing;
