#!perl -w
use 5.10.0;
use strict;
use Benchmark qw(:all);

use Data::Validator;
use Params::Validate qw(:all);

foreach my $mod (qw(Params::Validate Data::Validator)) {
    print $mod, "/", $mod->VERSION, "\n";
}

sub pv_add {
    my($x, $y) = validate_pos( @_, 1, 1);
    return $x + $y;
}

sub dv_add {
    state $v = Data::Validator->new(
        x => { },
        y => { },
    )->with('Sequenced');
    my $args = $v->validate(@_);
    return $args->{x} + $args->{y};
}

print "without type constraints\n";
cmpthese -1, {
    'P::Validate' => sub {
        my $x = pv_add(10, 20);
        $x == 30 or die $x;
    },
    'D::Validator' => sub {
        my $x = dv_add(10, 20);
        $x == 30 or die $x;
    },
};
