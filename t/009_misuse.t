#!perl -w
use strict;
use Test::More;
use Data::Validator;

eval {
    Data::Validator->new(
        foo => { isa => 'Int', does => 'Bar' },
    );
};
like $@, qr/Wrong definition for 'foo': /;
like $@, qr/You cannot use 'isa' and 'does' together/;

eval {
    Data::Validator->new(
        foo => { xor => 'nothing' },
    );
};
like $@, qr/Wrong definition for 'foo': /;
like $@, qr/Unknown parameter name 'nothing' specified as exclusive-or/;

eval {
    Data::Validator->new(
        foo => { hoge => 'nothing', fuga => 42 },
    );
};
like $@, qr/Wrong definition for 'foo': /;
like $@, qr/Unknown attributes: 'fuga' and 'hoge'/;

done_testing;

