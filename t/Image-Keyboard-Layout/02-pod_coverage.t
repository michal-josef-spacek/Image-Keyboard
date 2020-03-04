use strict;
use warnings;

use Test::NoWarnings;
use Test::Pod::Coverage 'tests' => 2;

# Test.
pod_coverage_ok('Image::Keyboard::Layout', 'Image::Keyboard::Layout is covered.');
