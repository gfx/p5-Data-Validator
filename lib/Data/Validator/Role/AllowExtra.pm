package Data::Validator::Role::AllowExtra;
use Mouse::Role;

sub parse_whole_args { 0 }

# returns($args, %extra_args)
around unknown_parameters => sub {
    my($next, $self, $rules, $args) = @_;
    my %knowns = map { $_->{name} => undef } @{$rules};
    return( $args,
        map {
            !exists $knowns{$_}
                ? ($_ => delete $args->{$_})
                : ()
        } keys %{$args} );
};

no Mouse::Role;
1;
__END__

=head1 NAME

Data::Validator::Role::AllowExtra - Allows extra arguments

=cut

