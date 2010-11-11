package Data::Validator::Role::Method;
use Mouse::Role;

has invocant => (
    is  => 'rw',
);

sub parse_whole_args { 0 }

around initialize => sub {
    my($next, $self, @args) = @_;
    $self->invocant(shift @args);
    return $self->$next(@args);
};

around finalize => sub {
    my($next, $self, $args) = @_;
    return( $self->invocant, $self->$next($args) );
};

no Mouse::Role;
1;

