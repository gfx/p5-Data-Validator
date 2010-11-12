package Data::Validator::Role::Confess;
use Mouse::Role;

sub parse_whole_args { 0 }

sub throw_error {
    my($self, $message) = @_;
    local $Carp::CarpLevel = $Carp::CarpLevel + 2;
    confess $message;
}

no Mouse::Role;
1;
__END__

=head1 NAME

Data::Validator::Role::Confess - Reports the stack trace on errors

=cut

