#!perl -w
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok 'Data::Validator';
}

diag "Testing Data::Validator/$Data::Validator::VERSION";
eval { require Moose };
diag "Moose/$Moose::VERSION";
eval { require Mouse };
diag "Mouse/$Mouse::VERSION";
