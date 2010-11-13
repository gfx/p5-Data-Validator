#!perl -w
use 5.10.0;
use strict;
use Benchmark qw(:all);

use Data::Validator;
use Params::Validate qw(:all);
use Smart::Args;

foreach my $mod (qw(Params::Validate Smart::Args Data::Validator)) {
    print $mod, "/", $mod->VERSION, "\n";
}

sub pv_add {
    my %args = validate( @_ => {
        x => { type => SCALAR },
        y => { type => SCALAR },
    });
    return $args{x} + $args{y};
}

sub sa_add {
    args my $x => 'Value', my $y => 'Value';
    return $x + $y;
}

sub dv_add {
    state $v = Data::Validator->new(
        x => 'Value',
        y => 'Value',
    );
    my $args = $v->validate(@_);
    return $args->{x} + $args->{y};
}

print "without type constraints\n";
cmpthese -1, {
    'P::Validate' => sub {
        my $x = pv_add({ x => 10, y => 10 });
    },
    'P::Validate/off' => sub {
        local $Params::Validate::NO_VALIDATION = 1;
        my $x = pv_add({ x => 10, y => 10 });
    },
    'S::Args' => sub {
        my $x = sa_add({ x => 10, y => 10 });
    },
    'D::Validator' => sub {
        my $x = dv_add({ x => 10, y => 10 });
    },
};
