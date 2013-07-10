# Pragmas.
use strict;
use warnings;

# Modules.
use Image::Keyboard;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Image::Keyboard::VERSION, 0.03, 'Version.');
