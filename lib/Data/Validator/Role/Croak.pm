package Data::Validator::Role::Croak;
use Mouse::Role;
use Carp ();
our @CARP_NOT = qw(Data::Validator);

sub throw_error {
    my($self, $message) = @_;
    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    Carp::croak($message);
}

no Mouse::Role;
1;
__END__

=for stopwords backtrace

=head1 NAME

Data::Validator::Role::Croak - Does not report backtrace on errors

=cut

