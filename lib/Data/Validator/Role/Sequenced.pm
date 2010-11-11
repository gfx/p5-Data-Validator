package Data::Validator::Role::Sequenced;
use Mouse::Role;
use Mouse::Util::TypeConstraints ();

sub parse_whole_args { 1 }

around initialize => sub {
    my($next, $self, @args) = @_;
    if(@args == 1 && Mouse::Util::TypeConstraints::HashRef($args[0])) {
        return { %{ $args[0] } }; # must be copied
    }
    my $rules = $self->rules;
    my %args;
    foreach my $i( 0 .. (@args - 1) ) {
        $args{ $rules->[$i]->{name} } = $args[$i];
    }
    return \%args;
};

no Mouse::Role;
1;

