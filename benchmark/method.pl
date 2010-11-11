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
    my $self = shift;
    my %args = validate( @_ => { x => 1, y => 1 } );
    return $args{x} + $args{y};
}

sub sa_add {
    args my $self, my $x, my $y;
    return $x + $y;
}

sub dv_add {
    state $v = Data::Validator->new(
        x => { },
        y => { },
    )->with('Method');
    my($self, $args) = $v->validate(@_);
    return $args->{x} + $args->{y};
}

print "methods without type constraints\n";
cmpthese -1, {
    'P::Validate' => sub {
        my $x = main::->pv_add({ x => 10, y => 10 });
    },
    'S::Args' => sub {
        my $x = main::->sa_add({ x => 10, y => 10 });
    },
    'D::Validator' => sub {
        my $x = main::->dv_add({ x => 10, y => 10 });
    },
};
