#!/usr/bin/env perl

use strict;
use warnings;

use File::Spec::Functions qw(catfile);
use File::Temp qw(tempdir tempfile);
use Image::Keyboard;
use Imager;
use Imager::Color;

# Image dir.
my $image_dir = tempdir(CLEANUP => 1);

# Button.
my $i_button = Imager->new(
        'xsize' => 100,
        'ysize' => 100,
);
$i_button->box(
        'color' => Imager::Color->new('#FF0000'),
        'filled' => 1,
);
my $button_file = 'button_file.png';
$i_button->write(
        'file' => catfile($image_dir, $button_file),
        'type' => 'png',
);

# Background.
my $i_background = Imager->new(
        'xsize' => 550,
        'ysize' => 550,
);
$i_background->box(
        'color' => Imager::Color->new('#00FF00'),
        'filled' => 1,
);
my $background_file = 'background_file.png';
$i_background->write(
        'file' => catfile($image_dir, $background_file),
        'type' => 'png',
);

# Config.
my $config_hr = {
        'background' => $background_file,
        'font' => {
                'color' => 'black',
                'size' => 20,
# TODO Vygenerovat nejaky minimalni font.
#               'file' => 'DejaVuSans.ttf',
        },
        'button' => {
                '1' => {
                        'text' => {
                                'string' => 1,
                        },
                        'image' => $button_file,
                        'pos' => {
                                'top' => 50,
                                'left' => 50,
                        },
                },
                '2' => {
                        'text' => {
                                'string' => 2,
                        },
                        'image' => $button_file,
                        'pos' => {
                                'top' => 50,
                                'left' => 200,
                        },
                },
                '3' => {
                        'text' => {
                                'string' => 3,
                        },
                        'image' => $button_file,
                        'pos' => {
                                'top' => 200,
                                'left' => 50,
                        },
                },
                '4' => {
                        'text' => {
                                'string' => 4,
                        },
                        'image' => $button_file,
                        'pos' => {
                                'top' => 200,
                                'left' => 200,
                        },
                },
        },
};

# Object.
my $keyboard = Image::Keyboard->new(
        'config' => $config_hr,
        'files_dir' => $image_dir,
);

# Save.
my (undef, $output_file) = tempfile();
$keyboard->image($output_file);

# Print to output.
print "Output file: $output_file\n";

# Output.
# TODO