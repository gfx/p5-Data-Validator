#!perl -w
use strict;
use Test::More;
use Test::Mouse;

use Data::Validator;

my $rule = Data::Validator->new(
    foo => 'Int',
)->with('Method');

does_ok $rule, 'Data::Validator::Role::Method';

done_testing;

