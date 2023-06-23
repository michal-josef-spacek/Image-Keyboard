#!/usr/bin/env perl

use strict;
use warnings;

use Image::Keyboard::Layout;

# Object.
my $obj = Image::Keyboard::Layout->new(
       'layout' => {
              'alt' => 'Alt',
              'ctrl' => 'Ctrl',
              'enter' => 'Enter',
              'lshift' => 'Shift',
              'rshift' => 'Shift',
       },
);

# Get ids.
my @ids = $obj->ids;

# Print out.
print map { $_."\n" } @ids;

# Output:
# alt
# ctrl
# enter
# lshift
# rshift