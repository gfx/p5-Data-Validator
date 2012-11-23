package Data::Validator::Role::StrictSequenced;
use Mouse::Role;
use Mouse::Util::TypeConstraints ();

around initialize => sub {
    shift; # original method; not used
    my $self = shift;

    my %args;
    my $rules = $self->rules;
    foreach my $i( 0 .. (@_ - 1) ) {
        my $rule = $rules->[$i] || +{ name => "[$i]" };
        $args{ $rule->{name} } = $_[$i];
    }

    return \%args;
};

no Mouse::Role;
1;
__END__

=head1 NAME

Data::Validator::Role::StrictSequenced - Deals with sequenced parameters.

=cut

