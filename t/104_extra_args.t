#!perl -w
use strict;
use Test::More;
use Data::Validator;

my $v = Data::Validator->new(
    foo => { },
)->with('AllowExtra');

my($args, %extra) = $v->validate( foo => 42, bar => 15 );
is_deeply $args,   { foo => 42 }, 'args';
is_deeply \%extra, { bar => 15 }, 'extra' or diag(explain(\%extra));

($args, %extra) = $v->validate( bar => 15, foo => 42 );
is_deeply $args,   { foo => 42 }, 'reversed order';
is_deeply \%extra, { bar => 15 };

$v = Data::Validator->new(
    foo => { },
)->with('AllowExtra', 'Method');

(my $self, $args, %extra) = $v->validate('MyClass', foo => 42, bar => 15 );
is $self, 'MyClass', 'with Method';
is_deeply $args,   { foo => 42 };
is_deeply \%extra, { bar => 15 };

($self, $args, %extra) = $v->validate('MyClass', bar => 15, foo => 42 );
is $self, 'MyClass', 'reversed order';
is_deeply $args,   { foo => 42 };
is_deeply \%extra, { bar => 15 };

$v = Data::Validator->new(
    foo => { },
)->with('Sequenced', 'AllowExtra');

($args, %extra) = $v->validate(42);
is_deeply $args,   { foo => 42 };
is_deeply \%extra, { };

($args, %extra) = $v->validate(42, { bar => 15 });
is_deeply $args,   { foo => 42 };
is_deeply \%extra, { bar => 15 };

($args, %extra) = $v->validate( 10, 20, 30 );
is_deeply $args,   { foo => 10 };
is_deeply \%extra, { '[1]' => 20, '[2]' => 30 };

done_testing;
