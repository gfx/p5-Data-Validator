use strict;
use warnings;
use inc::Module::Install;
use Module::Install::AuthorTests;
use Module::Install::Repository;

all_from 'lib/Data/Validator.pm';


requires 'Mouse'                     => 0.70;
requires 'MouseX::StrictConstructor' => 0.02;
requires 'MouseX::NativeTraits'      => 0.002;
test_requires 'Test::More' => '0.88';

auto_set_repository;

tests_recursive;
author_tests 'xt';


clean_files qw(
    Data-Validator-*
    *.stackdump
    cover_db *.gcov *.gcda *.gcno
    nytprof
    *.out
);

WriteAll(check_nmake => 0);
