#!perl -w
use 5.010_00;
use strict;
use Data::Validator;
use Data::Dumper;

sub get {
    state $v = Data::Validator->new(
        uri        => { isa => 'Str', xor => [qw(schema host path_query)] },

        schema     => { isa => 'Str', default => 'http' },
        host       => { isa => 'Str' },
        path_query => { isa => 'Str', default => '/' },

        method     => { isa => 'Str', default => 'GET' },
    );

    my $args = $v->validate(@_);
    print Dumper($args);
}

print get(@ARGV);

