package Data::Validator::Role::Method;
use Mouse::Role;

around validate => sub {
    my($next, $self, @args) = @_;
    return( shift(@args), $self->$next(@args) );
};

no Mouse::Role;
1;
__END__

=for stopwords invocant

=head1 NAME

Data::Validator::Role::Method - Deals with the invocant of methods

=cut

