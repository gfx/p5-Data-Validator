package Data::Validator::Role::SmartSequenced;
use Mouse::Role;
use Mouse::Util::TypeConstraints ();

around initialize => sub {
    shift; # original method; not used
    my $self = shift;

    my %args;
    if( @_ and Mouse::Util::TypeConstraints::HashRef($_[-1])
        and keys %{ $_[-1] } == grep { exists $_[-1]->{ $_->{name} } } @{ $self->rules } )
    {
        %args = %{ pop @_ };
    }

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

Data::Validator::Role::SmartSequenced - Deals with sequenced and named parameters

=cut

