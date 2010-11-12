#!perl -w
use 5.10.0;
use strict;
use Benchmark qw(:all);

use Data::Validator;

foreach my $mod (qw(MooseX::Params::Validate Data::Validator)) {
    print $mod, "/", $mod->VERSION, "\n";
}

{
    package Foo;
    use Moose;
    use MooseX::Params::Validate qw(:all);

    sub pv_add {
        my($self, %args) = validated_hash( \@_ =>
            x => { isa => 'Num' },
            y => { isa => 'Num' },
        );
        return $args{x} + $args{y};
    }

    sub dv_add {
        state $v = Data::Validator->new(
            x => 'Num',
            y => 'Num',
        )->with('Method');
        my($self, $args) = $v->validate(@_);
        return $args->{x} + $args->{y};
    }
}

my $foo = Foo->new();
$foo->pv_add(x => 2, y => 3) == 5 or die;
$foo->dv_add(x => 2, y => 3) == 5 or die;

print "without type constraints\n";
cmpthese -1, {
    'P::Validate' => sub {
        my $x = $foo->pv_add( x => 10, y => 10 );
    },
    'D::Validator' => sub {
        my $x = $foo->dv_add( x => 10, y => 10 );
    },
};
