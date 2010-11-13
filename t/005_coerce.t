#!perl -w
use strict;
use Test::More;

use Data::Validator;
use Mouse::Util::TypeConstraints;

subtype 'MyHash', as 'HashRef';
coerce 'MyHash',
    from 'ArrayRef', via { +{ @{$_} } };

my $v = Data::Validator->new(
    foo => 'MyHash',
);
isa_ok $v, 'Data::Validator';

my $args = $v->validate({ foo => { a => 42 } });
is_deeply $args, { foo => { a => 42 } };

$args = $v->validate({ foo => [ a => 42 ] });
is_deeply $args, { foo => { a => 42 } };

note 'failing cases';

eval {
    $v->validate({foo => 'bar'});
};
like $@, qr/Validation failed for 'MyHash' with value bar/, 'validation falure';

note 'coerce => 0';

$v = Data::Validator->new(
    foo => { isa => 'MyHash', coerce => 0 },
);
isa_ok $v, 'Data::Validator';

$args = $v->validate({ foo => { a => 42 } });
is_deeply $args, { foo => { a => 42 } };
eval {
    $v->validate({ foo => [ a => 42 ] });
};
like $@, qr/Validation failed for 'MyHash' with value ARRAY\(/;

done_testing;
