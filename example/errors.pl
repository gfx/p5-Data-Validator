#!perl -w
use 5.10.0;
use strict;
use Data::Validator;

sub add0 {
    my $args = {@_};
    return $args->{x} + $args->{y};
}

sub add1 {
    state $rule = Data::Validator->new(
        x => 'Int',
        y => 'Int',
    );
    my $args = $rule->validate(@_);
    return $args->{x} + $args->{y};
}


say "add(x => 1, y => 'foo')";
say '# produces a warning and returns a wrong result';
say eval { add0(x => 1, y => 'foo') } || $@;
say '# dies, saying y is invalid';
say eval { add1(x => 1, y => 'foo') } || $@;

say "add(x => 1)";
say '# produces a warning and returns a wrong result';
say eval { add0(x => 1) } || $@;
say '# dies, saying y is missing';
say eval { add1(x => 1) } || $@;

say "add(x => 1, y => 2, z => 3)";
say '# simply ignores an extra argument z';
say eval { add0(x => 1, y => 2, z => 3) } || $@;
say '# dies, saying z is unknown';
say eval { add1(x => 1, y => 2, z => 3) } || $@;
__END__

