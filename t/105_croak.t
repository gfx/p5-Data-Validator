#!perl -w
use strict;
use Test::More;
use Data::Validator;

{
    package A;
    sub aaa {
        my $v = Data::Validator->new(
            foo => { },
        )->with('Croak');
        $v->validate(@_);
    }
    sub bbb {
        aaa(@_);
    }
}

is_deeply A::aaa(foo => 42), { foo => 42 };

eval {
    A::bbb();
};
note $@;
like $@, qr/Missing parameter: 'foo'/;
like $@, qr/\Q@{[__FILE__]}/;
unlike $@, qr/A::bbb/;
unlike $@, qr/A::aaa/;

done_testing;
