#!perl -w
use 5.10.0;
use strict;
use Benchmark qw(:all);

use Data::Validator;

sub sseq_add {
    state $v = Data::Validator->new(
        x => { },
        y => { },
    )->with('SmartSequenced');
    my $args = $v->validate(@_);
    return $args->{x} + $args->{y};
}

sub seq_add {
    state $v = Data::Validator->new(
        x => { },
        y => { },
    )->with('Sequenced');
    my $args = $v->validate(@_);
    return $args->{x} + $args->{y};
}

print "without type constraints\n";
cmpthese -1, {
    'SmartSequenced' => sub {
        my $x = sseq_add(10, 20);
        $x == 30 or die $x;
    },
    'Sequenced' => sub {
        my $x = seq_add(10, 20);
        $x == 30 or die $x;
    },
};
