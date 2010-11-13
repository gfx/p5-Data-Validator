package Data::Validator::Role::NoThrow;
use Mouse::Role;

has errors => (
    is        => 'rw',
    isa       => 'ArrayRef',

    required  => 0,

    predicate => 'has_errors',
    clearer   => 'clear_errors',
);

around unknown_parameters => sub {
    my($next, $self, $rules, $args) = @_;
    my %unknowns = $self->$next($rules, $args);
    while(my($k, $v) = each %unknowns) {
        $args->{$k} = $v;
    }
    return %unknowns;
};

around found_errors => sub {
    my($next, $self, $args, @errors) = @_;
    $self->errors(\@errors);
    return $args;
};

no Mouse::Role;
1;
__END__

=head1 NAME

Data::Validator::Role::NoThrow - Does not throw errors

=cut

