package Data::Validator::Role::Croak;
use Mouse::Role;
use Carp ();
our @CARP_NOT = qw(Data::Validator);

sub parse_whole_args { 0 }

sub throw_error {
    my($self, $message) = @_;
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    Carp::croak($message);
}

no Mouse::Role;
1;
__END__

=head1 NAME

Data::Validator::Role::Croak - Does not report stack backtrace on errors

=cut

