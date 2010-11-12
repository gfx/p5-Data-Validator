#!perl -w
use strict;
use Test::More;

use Data::Validator;

foreach my $v(
        Data::Validator->new(
            foo => 'Num',
        )->with('Method', 'Sequenced'),
        Data::Validator->new(
            foo => 'Num',
        )->with('Sequenced', 'Method'),
    ) {
    note join ' ', map { $_->name }
        grep { !$_->is_anon_role } $v->meta->calculate_all_roles;
    isa_ok $v, 'Data::Validator';

    my($class, $args) = $v->validate('MyClass', { foo => 42 });
    is $class, 'MyClass';
    is_deeply $args, { foo => 42 };

    ($class, $args) = $v->validate('MyClass', 3.14);
    is $class, 'MyClass';
    is_deeply $args, { foo => 3.14 };

    note 'failing cases';

    eval {
        $v->validate('MyClass');
    };
    like $@, qr/Missing parameter: 'foo'/, 'missing parameters';

    eval {
        $v->validate('MyClass', {});
    };
    like $@, qr/Missing parameter: 'foo'/, 'missing parameters';

    eval {
        $v->validate('MyClass', {foo => 'bar'});
    };
    like $@, qr/Validation failed for 'Num' with value bar/, 'validation falure';
    eval {
        $v->validate('MyClass', 'bar');
    };
    like $@, qr/Validation failed for 'Num' with value bar/, 'validation falure';
}
done_testing;
