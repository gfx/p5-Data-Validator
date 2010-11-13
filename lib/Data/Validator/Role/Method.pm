package Data::Validator::Role::Method;
use Mouse::Role;

around validate => sub {
    my($next, $self, @args) = @_;
    return( shift(@args), $self->$next(@args) );
};

no Mouse::Role;
1;
__END__

=head1 NAME

Data::Validator::Role::Method - Deals with method invocants

=cut

