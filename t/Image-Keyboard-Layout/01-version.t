use strict;
use warnings;

use Image::Keyboard::Layout;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Image::Keyboard::Layout::VERSION, 0.04, 'Version.');
