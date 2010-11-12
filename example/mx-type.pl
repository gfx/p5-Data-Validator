#!perl -w
use strict;
use Data::Validator;
use MouseX::Types::URI;
use Data::Dumper;

my $v = Data::Validator->new( uri => 'URI' );

print Dumper($v->validate(uri => 'http://example.com/'));

