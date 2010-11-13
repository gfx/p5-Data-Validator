package Data::Validator::Role::AllowExtra;
use Mouse::Role;

has extra_args => (
    is         => 'rw',
    isa        => 'ArrayRef',
    auto_deref => 1,
    lazy       => 1,
    default    => sub { [] },
    required   => 0,
);

around unknown_parameters => sub {
    my($next, $self, $rules, $args) = @_;
    @{ $self->extra_args } = $self->$next($rules, $args);
    return;
};

around validate => sub {
    my($next, $self, @args) = @_;
    my @retvals = $self->$next(@args);
    push @retvals, $self->extra_args;
    @{$self->extra_args} = ();
    return @retvals;
};

no Mouse::Role;
1;
__END__

=head1 NAME

Data::Validator::Role::AllowExtra - Allows extra arguments

=cut

