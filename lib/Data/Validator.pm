package Data::Validator;
use 5.008_001;
use Mouse;
use Mouse::Meta::Attribute       ();
use Mouse::Util::TypeConstraints ();
use Mouse::Util                  ();
use Carp                         ();

our $VERSION = '0.01';

*_isa_tc  = \&Mouse::Util::TypeConstraints::find_or_create_isa_type_constraint;
*_does_tc = \&Mouse::Util::TypeConstraints::find_or_create_does_type_constraint;

has rules => (
    is       => 'ro',
    isa      => 'ArrayRef',
    required => 1,
);

no Mouse;

my %rule_attrs = map { $_ => undef }
    qw(isa does default optional xor);

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
            Carp::croak("Unknown attributes in a validation rule for '$name': "
                . $class->_unknown(\%rule_attrs, $rule));
        }

        # setup the rule
        if(defined $rule->{xor}) {
            $xor{$name} = Mouse::Util::TypeConstraints::ArrayRef($rule->{xor})
                    ?  $rule->{xor}
                    : [$rule->{xor}];
            $rule->{optional} = 1;
        }

        if(!exists $rule->{default}) {
            $rule->{default} = undef if delete $rule->{optional};
        }

        if(defined $rule->{isa}) {
            $rule->{type} = _isa_tc(delete $rule->{isa});
        }
        if(defined $rule->{does}) {
            defined($rule->{type})
                and Carp::croak("Rule error for '$name':"
                    . " You cannot use 'isa' and 'does' at the same time");
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
                    || Carp::croak("Unknown parameter name '$other_name'"
                        . " specified as exclusive-or by '$this'");
                exists $other_rule->{default}
                    or $other_rule->{default} = undef;

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

    my $nargs = scalar keys %{$args};
    my $used  = 0;
    foreach my $rule(@{ $rules }) {
        my $name = $rule->{name};
        next if exists $skip{$name};

        if(defined(my $value = $args->{$name})) {
            $self->_apply_type_constraint($rule, \$value)
                if exists $rule->{type};

            if($rule->{xor}) {
                foreach my $other_name( @{ $rule->{xor} } ) {
                    if(defined $args->{$other_name}) {
                        my $exclusive = Mouse::Util::quoted_english_list(
                            grep { defined $args->{$_} } @{$rule->{xor}} );
                        $self->throw_error(
                            "Exclusive parameters specified:"
                            . " '$name' v.s. $exclusive");
                    }
                    $skip{$other_name}++;

                    # setup placeholder for hash restriction
                    $args->{$other_name} = undef;
                }
            }
            $used++;
        }
        elsif(exists $rule->{default}) {
            $used++ if exists $args->{$name};

            my $default = $rule->{default};
            $args->{$name} = Mouse::Util::TypeConstraints::CodeRef($default)
                ? $default->()
                : $default;
            #XXX: should we apply rules to defaults?
        }
        else {
            $self->throw_error("Missing parameter named '$name'");
        }
    }

    if($used < $nargs) {
        $self->throw_error("Unknown prameters: "
            . $self->_unknown({ map { $_ => undef } @{$rules} }, $args) );
    }

    &Internals::SvREADONLY($args, 1);
    return $args;
}

__PACKAGE__->meta->add_method( initialize => \&Mouse::Object::BUILDARGS );

sub throw_error {
    my($self, $message) = @_;
    local $Carp::CarpLevel = $Carp::CarpLevel = 1;
    Carp::croak($message);
}

sub _apply_type_constraint {
    my($self, $rule, $value_ref) = @_;
    my $tc = $rule->{type};
    return if $tc->check(${$value_ref});

    if($rule->{should_coercion}) {
        ${$value_ref} = $tc->coerce(${$value_ref});
        return if $tc->check(${$value_ref});
    }
    $self->throw_error( $tc->get_message(${$value_ref}) );
}

sub _unknown {
    my($self, $knowns, $params) = @_;
    my @unknowns = grep { not exists $knowns->{$_} } keys %{$params};
    return Mouse::Util::quoted_english_list(@unknowns);
}


__PACKAGE__->meta->make_immutable;
__END__

=head1 NAME

Data::Validator - Rule based validator on type constraint subsystem

=head1 VERSION

This document describes Data::Validator version 0.01.

=head1 SYNOPSIS

    use 5.10.0;
    use Data::Validator;

    # for functions
    sub get {
        state $rule = Data::Validator->new(
            uri        => { isa => 'Str', xor => [qw(schema host path_query)] },

            schema     => { isa => 'Str', default => 'http' },
            host       => { isa => 'Str', default => '127.0.0.1' },
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
        )->with('Method', 'Sequenced');

        my($args = $rule->validate(@_);
        # ...
    }
    Foo->seq_method( 'bar' ); # seq() will get { foo => 'bar' }

=head1 DESCRIPTION

This is yet another validation library, based on C<Smart::Args> but
less smart.

B<< Any API will change without notice >>.

=head1 INTERFACE

=head2 C<< Data::Validator->new(@rules) :Validator >>

=head2 C<< $validator->validate(@args) :HashRef >>

=head1 EXTENTIONS

You can extends validators with C<Mouse::Role>.

Currently the following methods are extensible.

=head2 C<< $validator->initialize(@args) :HashRef >>

=head2 C<< $validator->finalize(@args) :List >>

=head2 C<< $validator->throw_error($message :Str) >>

=head1 TODO

=over

=item *

Validators for methods which deal with invocants (I<$class> and I<$self>).

=item *

Sequenced parameters; C<< foo(1, 2) >> makes C<< { x => 1, y => 2 } >>.

=item *

Smart parameters; C<< foo(1, 2) >> as sequenced, C<< foo({ x => 1, y => 2 }) >>
as named.

=back

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

gfx E<lt>gfuji@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, gfx. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
