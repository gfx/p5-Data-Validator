package Data::Validator::Role::AllowExtra;
use Mouse::Role;

sub parse_whole_args { 0 }

# returns($args, %extra_args)
around found_unknown_parameters => sub {
    my($next, $self, $rules, $args) = @_;
    return( $args, $self->unknown_parameters($rules, $args) );
};

no Mouse::Role;
1;
__END__

=head1 NAME

Data::Validator::Role::AllowExtra - Allows extra arguments

=cut

