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

my %rule_attrs = map { $_ => undef }
    qw(isa does default optional xor);

sub BUILDARGS {
    my $class = shift;
    my $mapping = $class->Mouse::Object::BUILDARGS(@_);

    my @rules;
    while(my($name, $rule) = each %{$mapping}) {
        if(!Mouse::Util::TypeConstraints::HashRef($rule)) {
            $rule = { isa => $rule };
        }

        # validate the rule
        my $used = 0;
        foreach my $attr(keys %rule_attrs) {
            exists($rule->{$attr}) and $used++;
        }
        if($used < keys %{$rule}) {
            $class->_report_unknown_args(\%rule_attrs, $rule);
        }

        # setup the rule

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

        &Internals::SvREADONLY($rule);
        push @rules, $rule;
    }

    return { rules => \@rules };
}

sub validate {
    my $self = shift;
    my $args = $self->Mouse::Object::BUILDARGS(@_);

    my $rules = $self->rules;

    my $used = 0;
    foreach my $rule(@{ $rules }) {
        my $name = $rule->{name};
        if(defined(my $value = $args->{$name})) {
            $self->_apply_rule($rule, \$value);
            $used++;
        }
        elsif(exists $rule->{default}) {
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

    if($used < keys %{$args}) {
        $self->_report_unknown_args({ map { $_ => undef } @{$rules} }, $args);
    }

    &Internals::SvREADONLY($args, 1); # makes it immutable
    return $args;
}

sub _apply_rule {
    my($self, $rule, $value_ref) = @_;
    if(defined(my $tc = $rule->{type})) {
        return if $tc->check(${$value_ref});

        if($rule->{should_coercion}) {
            ${$value_ref} = $tc->coerce(${$value_ref});
            return if $tc->check(${$value_ref});
        }
        $self->throw_error( $tc->get_message(${$value_ref}) );
    }
    return;
}

sub _report_unknown_args {
    my($self, $knowns, $params) = @_;
    my @unknowns = grep { not exists $knowns->{$_} } keys %{$params};
    $self->throw_error("Unknown arguments: "
        . Mouse::Util::quoted_english_list(@unknowns) );
}

sub throw_error {
    my($self, $message) = @_;
    local $Carp::CarpLevel = $Carp::CarpLevel = 1;
    Carp::croak($message);
}

no Mouse;
__PACKAGE__->meta->make_immutable;
__END__

=head1 NAME

Data::Validator - Perl extention to do something

=head1 VERSION

This document describes Data::Validator version 0.01.

=head1 SYNOPSIS

    use Data::Validator;

=head1 DESCRIPTION

# TODO

=head1 INTERFACE

# TODO

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<Dist::Maker::Template::Mouse>

=head1 AUTHOR

gfx E<lt>gfuji@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, gfx. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
