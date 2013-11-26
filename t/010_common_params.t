# https://gist.github.com/hirobanex/7658129
use strict;
use warnings;
use Test::More;

use Data::Validator;

my $base_param = +{
    member_id => {isa => 'Int', },
    type      => {isa => 'Int', default => 0, optional => 1 },
};

my $foo = Data::Validator->new(%$base_param);
my $bar = Data::Validator->new(%$base_param);

ok $foo->validate(member_id => 10);
ok $bar->validate(member_id => 10);

done_testing;
