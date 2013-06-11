package Data::Validator;
use 5.008_001;
use Mouse;
use Mouse::Util::TypeConstraints ();
use Mouse::Util                  ();
use Carp                         ();

our $VERSION = '1.03';

*_isa_tc  = \&Mouse::Util::TypeConstraints::find_or_create_isa_type_constraint;
*_does_tc = \&Mouse::Util::TypeConstraints::find_or_create_does_type_constraint;

has rules => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
);

no Mouse;

my %rule_attrs = map { $_ => undef }qw(
    isa does coerce
    default optional
    xor
    documentation
);

sub BUILDARGS {
    my($class, @mapping) = @_;

    my %xor;

    my @rules;
    while(my($name, $rule) = splice @mapping, 0, 2) {
        if(!Mouse::Util::TypeConstraints::HashRef($rule)) {
            $rule = { isa => $rule };
        }

        # validate the rule
        my $used = 0;
        foreach my $attr(keys %rule_attrs) {
            exists($rule->{$attr}) and $used++;
        }
        if($used < keys %{$rule}) {
            my @unknowns = grep { not exists $rule_attrs{$_} }  keys %{$rule};
            Carp::croak("Wrong definition for '$name':"
                . ' Unknown attributes: '
                . Mouse::Util::quoted_english_list(@unknowns) );
        }

        # setup the rule
        if(defined $rule->{xor}) {
            my @xors = Mouse::Util::TypeConstraints::ArrayRef($rule->{xor})
                    ? @{$rule->{xor}}
                    :  ($rule->{xor});
            $xor{$name} = $rule->{xor} = \@xors;
        }

        if(defined $rule->{isa}) {
            $rule->{type} = _isa_tc(delete $rule->{isa});
        }
        if(defined $rule->{does}) {
            defined($rule->{type})
                and Carp::croak("Wrong definition for '$name':"
                    . q{ You cannot use 'isa' and 'does' together});
            $rule->{type} = _does_tc(delete $rule->{does});
        }

        if(defined $rule->{type} && not defined $rule->{coerce}) {
            $rule->{coerce} = $rule->{type}->has_coercion;
        }

        $rule->{name} = $name;

        push @rules, $rule;
    }

    # to check xor first and only once, move xor configuration into front rules
    if(%xor) {
        my %byname = map { $_->{name} => $_ } @rules;
        while(my($this, $others) = each %xor) {
            foreach my $other_name(@{$others}) {
                my $other_rule = $byname{$other_name}
                    || Carp::croak("Wrong definition for '$this':"
                        . " Unknown parameter name '$other_name'"
                        . " specified as exclusive-or");

                push @{$other_rule->{xor} ||= []}, $this;
            }
        }
    }

    return { rules => \@rules };
}

sub with {
    my($self, @roles) = @_;
    foreach my $role(@roles) {
        next if ref $role;
        $role = Mouse::Util::load_first_existing_class(
            __PACKAGE__ . '::Role::' . $role,
            $role,
        );
    }
    Mouse::Util::apply_all_roles($self, @roles);
    return $self;
}

sub find_rule {
    my($self, $name) = @_;
    foreach my $rule(@{$self->rules}) {
        return $rule if $rule->{name} eq $name;
    }
    return undef;
}

sub validate {
    my $self = shift;
    my $args = $self->initialize(@_);

    my %skip;
    my @errors;
    my @missing;
    my $nargs = scalar keys %{$args};
    my $used  = 0;
    my $rules = $self->rules;
    RULE: foreach my $rule(@{ $rules }) {
        my $name = $rule->{name};
        next RULE if exists $skip{$name};

        if(exists $args->{$name}) {

            if(exists $rule->{type}) {
                my $err = $self->apply_type_constraint($rule, $args, $name);
                if($err) {
                    push @errors, $self->make_error(
                        type    => 'InvalidValue',
                        message => $err,
                        name    => $name,
                    );
                    next RULE;
                }
            }

            if($rule->{xor}) {
                # checks conflicts with exclusive arguments
                foreach my $other_name( @{ $rule->{xor} } ) {
                    if(exists $args->{$other_name}) {
                        push @errors, $self->make_error(
                            type    => 'ExclusiveParameter',
                            message => "Exclusive parameters passed together:"
                                     . " '$name' v.s. '$other_name'",
                            name    => $name,
                            conflict=> $other_name,
                        );
                    }
                    $skip{$other_name}++;
                }
            }
            $used++;
        }
        elsif(exists $rule->{default}) {
            my $default = $rule->{default};
            $args->{$name} = Mouse::Util::TypeConstraints::CodeRef($default)
                ? $default->($self, $rule, $args)
                : $default;
        }
        elsif(!$rule->{optional}) {
            push @missing, $rule;
        }
    }


    if(@missing) {
        MISSING: foreach my $rule(@missing) {
            my $name = $rule->{name};
            next if exists $skip{$name};

            my @xors;
            if($rule->{xor}) {
                foreach my $other_name(@{$rule->{xor}}) {
                    next MISSING if exists $args->{$other_name};
                    push @xors, $other_name;
                }
            }
            my $real_missing = @xors
                ? sprintf(q{'%s' (or %s)},
                    $name, Mouse::Util::quoted_english_list(@xors) )
                : sprintf(q{'%s'}, $name);
            push @errors, $self->make_error(
                type    => 'MissingParameter',
                message => "Missing parameter: $real_missing",
                name    => $name,
            );
        }
    }


    if($used < $nargs) {
        my %unknowns = $self->unknown_parameters($rules, $args);
        if(keys %unknowns) {
            foreach my $name( sort keys %unknowns ) {
                push @errors, $self->make_error(
                    type    => 'UnknownParameter',
                    message => "Unknown parameter: '$name'",
                    name    => $name,
                );
            }
        }
    }

    # make it restricted
    &Internals::SvREADONLY($args, 1);

    if(@errors) {
        $args = $self->found_errors($args, @errors);
    }

    return $args;
}

__PACKAGE__->meta->add_method( initialize => \&Mouse::Object::BUILDARGS );

sub unknown_parameters {
    my($self, $rules, $args) = @_;
    my %knowns  = map { $_->{name} => undef } @{$rules};
    return map {
        !exists $knowns{$_}
            ? ($_ => delete $args->{$_})
            : ()
    } keys %{$args};
}

sub found_errors {
    my($self, $args, @errors) = @_;
    my $msg = '';
    foreach my $e(@errors) {
        $msg .= $e->{message} . "\n";
    }
    $self->throw_error($msg . '... found');
}

sub make_error {
    my($self, %e) = @_;
    return \%e;
}

sub throw_error {
    my($self, $message) = @_;
    local $Carp::CarpLevel = $Carp::CarpLevel + 2; # &throw_error + &validate
    confess($message);
}

sub apply_type_constraint {
    my($self, $rule, $args, $name) = @_;
    my $tc = $rule->{type};
    return '' if $tc->check($args->{$name});

    if($rule->{coerce}) {
        my $value = $tc->coerce($args->{$name});
        if($tc->check($value)) {
            $args->{$name} = $value; # commit
            return '';
        }
    }

    return "Invalid value for '$rule->{name}': "
        . $tc->get_message($args->{$name});
}

__PACKAGE__->meta->make_immutable;
__END__

=for stopwords invocant validators backtrace

=head1 NAME

Data::Validator - Rule based validator on type constraint system

=head1 VERSION

This document describes Data::Validator version 1.03.

=head1 SYNOPSIS

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
    Foo->seq_method( 'bar' ); # seq() will get { foo => 'bar' }

=head1 DESCRIPTION

This is yet another validation library, based on C<Smart::Args> but
less smart.

This is designed for general data validation. For example, it is useful for CSV, JSON, XML, and so on.

=head2 Concepts

=over

=item Natural as Perl code

I love C<Smart::Args> because it is really stylish, but it does not seem
Perl-ish.

Thus, I have designed C<Data::Validator> in more Perl-ish way
with full of C<Smart::Args> functionality.

=item Basics on type constraint system

Moose's type constraint system is awesome, and so is Mouse's. In fact,
Mouse's type constraints are much faster than Moose's so that you need not
hesitate to check types.

Thus, I have made C<Data::Validator> on Mouse's type constraint system.

=item Pure Perl

Although I do not hesitate to depend on XS modules, some people think that
XS modules are hard to install.

Thus, I have written C<Data::Validator> in pure Perl and selected dependent
modules which work in pure Perl.

=item Performance

Validators should be as fast as possible because they matter only for illegal
inputs. Otherwise, one would want something like I<no validation> option.

This is much faster than C<Params::Validate>, which has an XS backend, though.

=back

=head1 INTERFACE

=head2 C<< Data::Validator->new( $arg_name => $rule [, ...]) :Validator >>

Creates a validation rule. You should cache the rules for performance.

Attributes for I<$rule> are as follows:

=over

=item C<< isa => $type : Str|Object >>

The type of the rule, which can be a Mouse type constraint name, a class name,
or a type constraint object of either Mouse or Moose (i.e. it's duck-typed).

=item C<< does => $role : Str|Object >>

The type of the rule, which can be a Mouse type constraint name, a role name,
or a type constraint object of either Mouse or Moose (i.e. it's duck-typed).

Note that you cannot use it with the C<isa> attribute.

=item C<< coerce => $should_coercion : Bool >>

If false, the rule does not try to coerce when the validation fails.
Default to true.

=item C<< default=> $value : Any | CodeRef >>

The default value for the argument.
If it is a CODE reference, it is called in scalar context as
C<< $default->($validator, $rule, $args) >> and its return value
is used as a default value.

Because arguments are validated in the order of definitions, C<default>
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

Unlike Moose/Mouse's C<default>, any references are allowed, but note that
they are statically allocated.

=item C<< optional => $value : Bool >>

If true, users can omit the argument. Default to false.

=item C<< xor => $exclusives : ArrayRef >>

Exclusive arguments, which users cannot pass together.

=item C<< documentation => $doc : Str >>

Descriptions of the argument.

This is not yet used anywhere.

=back

=head2 C<< $validator->find_rule($name :Str) >>

Finds the rule named I<$name>. Provided for error handling.

=head2 C<< $validator->with(@extensions) :Validator >>

Applies I<@extensions> to I<$validator> and returns itself.

See L</EXTENSIONS> for details.

=head2 C<< $validator->validate(@args) :HashRef >>

Validates I<@args> and returns a restricted HASH reference.

Restricted hashes are hashes which do not allow to access non-existing keys,
so you must check a key C<exists> in the hash before fetching its values.

=head1 EXTENSIONS

There are extensions which changes behaviours of C<validate()>.

=head2 Method

Takes the first argument as an invocant (i.e. class or object instance),
and returns it as the first value:

    my($invocant, $args) = $rule->validate(@_);

=head2 StrictSequenced

Deals with arguments in sequenced style, where users should pass
arguments by the order of argument rules, instead of by-name.

Note that single HASH ref argument was dealt as named-style arguments,
but this feature is NOT available since version 1.01.

=head2 Sequenced

Deals with arguments in sequenced style, where users should pass
arguments by the order of argument rules, instead of by-name.

Note that if the last argument is a HASH reference, it is regarded as
named-style arguments.

=head2 AllowExtra

Regards unknown arguments as extra arguments, and returns them as
a list of name-value pairs:

    my($args, %extra) = $rule->validate(@_);

=head2 NoThrow

Does not throw errors. Instead, it provides validators with the C<errors>
attribute:

    my $args = $v->validate(@_); # it never throws errors
    if($v->has_errors) {
        my $errors = $v->clear_errors;
        foreach my $e(@{$errors}) {
            # $e has 'type', 'message' and 'name'
            print $e->{message}, "\n";
        }
    }

=head2 Croak

Does not report stack backtrace on errors, i.e. uses C<croak()> instead
of C<confess()> to throw errors.

=head2 NoRestricted

Does not make the argument hash restricted.

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<Smart::Args>

L<Params::Validate>

L<Sub::Args>

L<MooseX::Params::Validate>

L<Mouse>

L<Hash::Util> for a restricted hash.

=head1 AUTHOR

Fuji, Goro (gfx) E<lt>gfuji@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Fuji Goro (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
