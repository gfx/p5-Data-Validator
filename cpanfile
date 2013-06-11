requires 'Mouse', '0.93';
requires 'perl', '5.008001';

on build => sub {
    requires 'ExtUtils::MakeMaker', '6.59';
};

on test => sub {
    requires 'Test::More', '0.88';
    requires 'Test::Requires';
};
