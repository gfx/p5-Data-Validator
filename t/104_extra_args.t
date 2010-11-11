#!perl -w
use strict;
use Test::More;
use Data::Validator;

my $v = Data::Validator->new(
    foo => 'Int',
)->with('AllowExtra');

my($args, %extra) = $v->validate( foo => 42, bar => 15 );
is_deeply $args,   { foo => 42 };
is_deeply \%extra, { bar => 15 };

($args, %extra) = $v->validate( bar => 15, foo => 42 );
is_deeply $args,   { foo => 42 }, 'reversed order';
is_deeply \%extra, { bar => 15 };

$v = Data::Validator->new(
    foo => 'Int',
)->with('AllowExtra', 'Method');

(my $self, $args, %extra) = $v->validate('MyClass', foo => 42, bar => 15 );
is $self, 'MyClass', 'with Method';
is_deeply $args,   { foo => 42 };
is_deeply \%extra, { bar => 15 };

($self, $args, %extra) = $v->validate('MyClass', bar => 15, foo => 42 );
is $self, 'MyClass', 'reversed order';
is_deeply $args,   { foo => 42 };
is_deeply \%extra, { bar => 15 };
done_testing;

