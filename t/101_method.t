#!perl -w
use strict;
use Test::More;

use Data::Validator;

my $v = Data::Validator->new(
    foo => 'Num',
)->with('Method');
isa_ok $v, 'Data::Validator';

my($class, $args) = $v->validate('MyClass', { foo => 42 });
is $class, 'MyClass';
is_deeply $args, { foo => 42 };

($class, $args) = $v->validate('MyClass', { foo => 3.14 });
is $class, 'MyClass';
is_deeply $args, { foo => 3.14 };

note 'failing cases';

eval {
    $v->validate('MyClass');
};
like $@, qr/Missing parameter: 'foo'/, 'missing parameters';

eval {
    $v->validate('MyClass', {foo => 'bar'});
};
like $@, qr/Validation failed for 'Num' with value bar/, 'validation falure';

done_testing;
