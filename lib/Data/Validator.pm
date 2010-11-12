package Data::Validator;
use 5.008_001;
use Mouse;
use Mouse::Util::TypeConstraints ();
use Mouse::Util                  ();
use Carp                         ();

our $VERSION = '0.03';

*_isa_tc  = \&Mouse::Util::TypeConstraints::find_or_create_isa_type_constraint;
*_does_tc = \&Mouse::Util::TypeConstraints::find_or_create_does_type_constraint;

has rules => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
);

no Mouse;

my %rule_attrs = map { $_ => undef }
    qw(isa does default optional xor documentation);

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
            $xor{$name} = Mouse::Util::TypeConstraints::ArrayRef($rule->{xor})
                    ?  $rule->{xor}
                    : [$rule->{xor}];
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

        if(defined $rule->{type}) {
            $rule->{should_coercion} = $rule->{type}->has_coercion;
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
        $role = Mouse::Util::load_first_existing_class(
            __PACKAGE__ . '::Role::' . $role,
            $role,
        );
    }
    @roles = sort { $b->parse_whole_args <=> $a->parse_whole_args } @roles;
    Mouse::Util::apply_all_roles($self,
        map { $_ => { -excludes => 'parse_whole_args' } } @roles);
    return $self;
}

sub validate {
    my $self = shift;
    my $args = $self->initialize(@_);

    my $rules = $self->rules;
    my %skip;

    my @errors;
    my @missing;
    my $nargs = scalar keys %{$args};
    my $used  = 0;
    RULE: foreach my $rule(@{ $rules }) {
        my $name = $rule->{name};
        next RULE if exists $skip{$name};

        if(exists $args->{$name}) {

            if(exists $rule->{type}) {
                my $err = $self->apply_type_constraint($rule, \$args->{$name});
                if($err) {
                    push @errors, {
                        type    => 'InvalidValue',
                        message => $err,
                        rule    => $rule,
                        value   => $args->{$name},
                    };
                    next RULE;
                }
            }

            if($rule->{xor}) {
                # checks conflickts with exclusive arguments
                foreach my $other_name( @{ $rule->{xor} } ) {
                    if(exists $args->{$other_name}) {
                        my $exclusive = Mouse::Util::quoted_english_list(
                            grep { exists $args->{$_} } @{$rule->{xor}} );
                        push @errors, {
                            type    => 'ExclusiveParameter',
                            message => "Exclusive parameters passed together:"
                                     . " '$name' v.s. $exclusive",
                            rule    => $rule,
                        };
                        next RULE;
                    }
                    $skip{$other_name}++;
                }
            }
            $used++;
        }
        elsif(exists $rule->{default}) {
            my $default = $rule->{default};
            $args->{$name} = Mouse::Util::TypeConstraints::CodeRef($default)
                ? $default->()
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
            next if exists $args->{$name};

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
            push @errors, {
                type    => 'MissingParameter',
                message => "Missing parameter: $real_missing",
                rule    => $rule,
            };
        }
    }

    &Internals::SvREADONLY($args, 1);

    if($used < $nargs) {
        my %unknowns = $self->unknown_parameters($rules, $args);
        foreach my $name( sort keys %unknowns ) {
            push @errors, {
                type    => 'UnknownParameter',
                message => "Unknown parameter: '$name'",
                value   => $unknowns{$name},
            };
        }
    }

    if(@errors) {
        $self->found_errors($args, @errors);
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

sub throw_error {
    my($self, $message) = @_;
    local $Carp::CarpLevel = $Carp::CarpLevel = 1;
    Carp::croak($message);
}

sub apply_type_constraint {
    my($self, $rule, $value_ref) = @_;
    my $tc = $rule->{type};
    return '' if $tc->check(${$value_ref});

    if($rule->{should_coercion}) {
        my $value = $tc->coerce(${$value_ref});
        if($tc->check($value)) {
            ${$value_ref} = $value;
            return '';
        }
    }

    return "Illegal value for '$rule->{name}' because: "
        . $tc->get_message(${$value_ref});
}

__PACKAGE__->meta->make_immutable;
__END__

=head1 NAME

Data::Validator - Rule based validator on type constraint system

=head1 VERSION

This document describes Data::Validator version 0.03.

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
        )->with('Sequenced');

        my $args = $rule->validate(@_);
        # ...
    }
    seq( 'bar' );          # seq() will get { foo => 'bar' }
    seq({ foo => 'bar' }); # named style are available!


    # both Method and Sequenced
    sub seq_method {
        state $rule = Data::Validator->new(
            foo => 'Str',
        )->with( 'Method', 'Sequenced');

        my($self, $args) = $rule->validate(@_);
        # ...
    }
    Foo->seq_method( 'bar' ); # seq() will get { foo => 'bar' }

=head1 DESCRIPTION

This is yet another validation library, based on C<Smart::Args> but
less smart.

This is under development. B<< Any API will change without notice >>.

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
hesitate to use type validations.

Thus, I have made C<Data::Validator> based on Mouse's type constraint system.

=item Pure Perl

Although I do not hesitate to depend on XS modules, some people think that
XS modules are hard to install.

Thus, I have written C<Data::Validator> in pure Perl and selected dependent
modules which work in pure Perl.

=item Performance

I think validators should be as fast as possible because they matter only
or illegal inputs.

This is much faster than C<Params::Validate>, which has an XS backend, though.

=back

=head1 INTERFACE

=head2 C<< Data::Validator->new( $arg_name => $rule [, ...]) :Validator >>

Creates a validation rule.

Attributes for I<$rule> are as follows:

=over

=item C<< isa => $type : Str|Object >>

=item C<< does => $role : Str|Object >>

=item C<< optional => $value : Bool >>

=item C<< xor => $exclusives : ArrayRef >>

=item C<< documentation => $doc : Str >>

=back

=head2 C<< $validator->with(@extentions) :Validator >>

Applies I<@extentions> to I<$validator> and returns itself.

See L</EXTENTIONS> for details.

=head2 C<< $validator->validate(@args) :HashRef >>

Validates I<@args> and returns a restricted HASH reference.

Restricted hashes are hashes which do not allow to access non-existing keys,
so you must check a key C<exists> in the hash before fetching its values.

=head1 EXTENTIONS

There are extentions which changes behaviours of C<validate()>.

=head2 Method

Takes the first argument as an invocant (i.e. class or object instance),
and returns it as the first value:

    my($invocant, $args) = $rule->validate(@_);

=head2 Sequenced

Deals with arguments in sequenced style, where users should pass
arguments by the order of argument rules, instead of by-name.

Note that if the last argument is a HASH reference, it is regarded as
named-style arguments.

=head3 AllowExtra

Regards unknown arguments as extra arguments, and returns them as
a list of name-value pairs:

    my($args, %extra) = $rule->validate(@_);

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<Params::Validate>

L<Smart::Args>

L<Sub::Args>

L<Mouse>

=head1 AUTHOR

Fuji, Goro (gfx) E<lt>gfuji@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Fuji Goro (gfx). All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
