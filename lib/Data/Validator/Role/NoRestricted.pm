package Data::Validator::Role::NoRestricted;
use Mouse::Role;

around validate => sub {
    my($next, $self, @args) = @_;
    my $args = $self->$next(@args);
    &Internals::SvREADONLY($args, 0);
    return $args;
};

no Mouse::Role;
1;
__END__

=head1 NAME

Data::Validator::Role::NoRestricted - Makes the argument hash no restricted

=cut

