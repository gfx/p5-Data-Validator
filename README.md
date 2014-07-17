# NAME

Data::Validator - Rule based validator on type constraint system

# VERSION

This document describes Data::Validator version 1.07.

# SYNOPSIS

    use 5.10.0;
    use Data::Validator;

    # for functions
    sub get {
        state $rule = Data::Validator->new(
            uri        => { isa => 'Str', xor => [qw(schema host path_query)] },

            schema     => { isa => 'Str', default => 'http' },
            host       => { isa => 'Str' },
            path_query => { isa => 'Str', default => '/' },

            method     => { isa => 'Str', default => 'GET' },
        );

        my $args = $rule->validate(@_);
        # ...
    }
    get( uri => 'http://example.com/' );

    # for methods
    sub method {
        state $rule = Data::Validator->new(
            foo => 'Str',
        )->with('Method');

        my($self, $args) = $rule->validate(@_);
        # ...
    }
    Foo->method( foo => 'bar' );



    # using sequenced parameters
    sub seq {
        state $rule = Data::Validator->new(
            foo => 'Str',
        )->with('StrictSequenced');

        my $args = $rule->validate(@_);
        # ...
    }
    seq( 'bar' );          # seq() will get { foo => 'bar' }
    seq({ foo => 'bar' }); # named style are NOT available!



    # using Method and StrictSequenced together
    sub seq_method {
        state $rule = Data::Validator->new(
            foo => 'Str',
        )->with( 'Method', 'StrictSequenced');

        my($self, $args) = $rule->validate(@_);
        # ...
    }
    Foo->seq_method( 'bar' ); # seq_method() will get { foo => 'bar' }



    # using sequenced and named parameters
    sub smart_seq {
        my $rule = Data::Validator->new(
            r1 => 'Str',
            r2 => 'HashRef',  # accept this
            o1 => { isa => 'Str', default => 'yes' },
            o2 => { isa => 'Num', optional => 1 },
        )->with('SmartSequenced');

        my $args = $rule->validate(@_);
        # ...
    }

    # all will get { r1 => 'foo', r2 => { val => 'bar' }, o1 => 'yes' }

    # mixed style(recommend)
    smart_seq( 'foo', { val => 'bar' }, { o1 => 'yes' } );
    smart_seq( 'foo', { val => 'bar' } );

    # also accept sequenced style
    smart_seq( 'foo', { val => 'bar' }, 'yes' );
    smart_seq( 'foo', { val => 'bar' } );

    # also accept named style
    smart_seq( { r1 => 'foo', r2 => { val => 'bar' }, o1 => 'yes' } );
    smart_seq( { r1 => 'foo', r2 => { val => 'bar' } } );



# DESCRIPTION

This is yet another validation library, based on `Smart::Args` but
less smart.

This is designed for general data validation. For example, it is useful for CSV, JSON, XML, and so on.

## Concepts

- Natural as Perl code

    I love `Smart::Args` because it is really stylish, but it does not seem
    Perl-ish.

    Thus, I have designed `Data::Validator` in more Perl-ish way
    with full of `Smart::Args` functionality.

- Basics on type constraint system

    Moose's type constraint system is awesome, and so is Mouse's. In fact,
    Mouse's type constraints are much faster than Moose's so that you need not
    hesitate to check types.

    Thus, I have made `Data::Validator` on Mouse's type constraint system.

- Pure Perl

    Although I do not hesitate to depend on XS modules, some people think that
    XS modules are hard to install.

    Thus, I have written `Data::Validator` in pure Perl and selected dependent
    modules which work in pure Perl.

- Performance

    Validators should be as fast as possible because they matter only for illegal
    inputs. Otherwise, one would want something like _no validation_ option.

    This is much faster than `Params::Validate`, which has an XS backend, though.

# INTERFACE

## `Data::Validator->new( $arg_name => $rule [, ...]) :Validator`

Creates a validation rule. You should cache the rules for performance.

Attributes for _$rule_ are as follows:

- `isa => $type : Str|Object`

    The type of the rule, which can be a Mouse type constraint name, a class name,
    or a type constraint object of either Mouse or Moose (i.e. it's duck-typed).

- `does => $role : Str|Object`

    The type of the rule, which can be a Mouse type constraint name, a role name,
    or a type constraint object of either Mouse or Moose (i.e. it's duck-typed).

    Note that you cannot use it with the `isa` attribute.

- `coerce => $should_coercion : Bool`

    If false, the rule does not try to coerce when the validation fails.
    Default to true.

- `default=> $value : Any | CodeRef`

    The default value for the argument.
    If it is a CODE reference, it is called in scalar context as
    `$default->($validator, $rule, $args)` and its return value
    is used as a default value.

    Because arguments are validated in the order of definitions, `default`
    callbacks can rely on the previously-filled values:

        my $v = Data::Validator->new(
            foo => { default => 99 },
            bar => { default => sub {
                my($validator, $this_rule, $args) = @_;
                return $args->{foo} + 1;
            } },
        );
        $v->validate();          # bar is 100
        $v->validate(foo => 42); # bar is 43

    Unlike Moose/Mouse's `default`, any references are allowed, but note that
    they are statically allocated.

- `optional => $value : Bool`

    If true, users can omit the argument. Default to false.

- `xor => $exclusives : ArrayRef`

    Exclusive arguments, which users cannot pass together.

- `documentation => $doc : Str`

    Descriptions of the argument.

    This is not yet used anywhere.

## `$validator->find_rule($name :Str)`

Finds the rule named _$name_. Provided for error handling.

## `$validator->with(@extensions) :Validator`

Applies _@extensions_ to _$validator_ and returns itself.

See ["EXTENSIONS"](#extensions) for details.

## `$validator->validate(@args) :HashRef`

Validates _@args_ and returns a restricted HASH reference.

Restricted hashes are hashes which do not allow to access non-existing keys,
so you must check a key `exists` in the hash before fetching its values.

# EXTENSIONS

There are extensions which changes behaviours of `validate()`.

## Method

Takes the first argument as an invocant (i.e. class or object instance),
and returns it as the first value:

    my($invocant, $args) = $rule->validate(@_);

## SmartSequenced

Deals with arguments in mixing sequenced style and named style.
The sequenced style should be passed by the order of argument rules,
and the named style arguments should be the last argument as HASH ref.

The typical usage is that the required arguments as sequenced style,
and some optional arguments as named style.

## StrictSequenced

Deals with arguments in sequenced style, where users should pass
arguments by the order of argument rules, instead of by-name.

Note that single HASH ref argument was dealt as named-style arguments,
but this feature is NOT available since version 1.01.

## Sequenced

Deals with arguments in sequenced style, where users should pass
arguments by the order of argument rules, instead of by-name.

Note that if the last argument is a HASH reference, it is regarded as
named-style arguments.

## AllowExtra

Regards unknown arguments as extra arguments, and returns them as
a list of name-value pairs:

    my($args, %extra) = $rule->validate(@_);

## NoThrow

Does not throw errors. Instead, it provides validators with the `errors`
attribute:

    my $args = $v->validate(@_); # it never throws errors
    if($v->has_errors) {
        my $errors = $v->clear_errors;
        foreach my $e(@{$errors}) {
            # $e has 'type', 'message' and 'name'
            print $e->{message}, "\n";
        }
    }

## Croak

Does not report stack backtrace on errors, i.e. uses `croak()` instead
of `confess()` to throw errors.

## NoRestricted

Does not make the argument hash restricted.

# DEPENDENCIES

Perl 5.8.1 or later.

# BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

# SEE ALSO

[Smart::Args](https://metacpan.org/pod/Smart::Args)

[Params::Validate](https://metacpan.org/pod/Params::Validate)

[Sub::Args](https://metacpan.org/pod/Sub::Args)

[MooseX::Params::Validate](https://metacpan.org/pod/MooseX::Params::Validate)

[Mouse](https://metacpan.org/pod/Mouse)

[Hash::Util](https://metacpan.org/pod/Hash::Util) for a restricted hash.

# AUTHOR

Fuji, Goro (gfx) <gfuji@cpan.org>

# LICENSE AND COPYRIGHT

Copyright (c) 2010, Fuji Goro (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
