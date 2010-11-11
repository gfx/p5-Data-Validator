package Data::Validator::Role::Method;
use Mouse::Role;

sub parse_whole_args { 0 }

around validate => sub {
    my($next, $self, @args) = @_;
    my $invocant = shift @args;
    return( $invocant, $self->$next(@args) );
};

no Mouse::Role;
1;
__END__

=head1 NAME

Data::Validator::Role::Method - Deals with method invocants

=cut

