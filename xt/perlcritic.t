use strict;
use Test::More;
eval q{
    use Perl::Critic 1.105;
    use Test::Perl::Critic -profile => \do { local $/; <DATA> };
};
plan skip_all => "Test::Perl::Critic is not available." if $@;
all_critic_ok('lib');
__DATA__

exclude=ProhibitStringyEval ProhibitExplicitReturnUndef RequireBarewordIncludes

[TestingAndDebugging::ProhibitNoStrict]
allow=refs

[TestingAndDebugging::RequireUseStrict]
equivalent_modules = Mouse Mouse::Role Mouse::Exporter Mouse::Util Mouse::Util::TypeConstraints Moose Moose::Role Moose::Exporter Moose::Util::TypeConstraints Any::Moose

[TestingAndDebugging::RequireUseWarnings]
equivalent_modules = Mouse Mouse::Role Mouse::Exporter Mouse::Util Mouse::Util::TypeConstraints Moose Moose::Role Moose::Exporter Moose::Util::TypeConstraints Any::Moose
