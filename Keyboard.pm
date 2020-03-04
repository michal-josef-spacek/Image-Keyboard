package Image::Keyboard;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use File::Spec::Functions qw(catfile);
use Imager;
use List::MoreUtils qw(none);

our $VERSION = 0.04;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Configuration.
	$self->{'config'} = undef;

	# Disable buttons.
	$self->{'disabled'} = [];

	# Images directory.
	$self->{'files_dir'} = undef;

	# Process params.
	set_params($self, @params);

	# Check for config.
	if (! defined $self->{'config'}) {
		err "Parameter 'config' is required.";
	}

	# Config initialization.
	$self->_config_init;

	# Object.
	return $self;
}

# Get buttons ids.
sub buttons {
	my $self = shift;
	return sort { $a <=> $b } @{$self->{'buttons'}};
}

# Get or set configuration.
sub config {
	my ($self, $config_hr) = @_;
	if (defined $config_hr) {
		$self->{'config'} = $config_hr;
		$self->_config_init;
	}
	return $self->{'config'};
}

# Create image.
sub image {
	my ($self, $image, $type) = @_;

	# Check images directory.
	if (defined $self->{'files_dir'} && ! -d $self->{'files_dir'}) {
		err "Bad files directory '$self->{'files_dir'}'.";
	}

	# Create image.
	if (! $self->{'config'}->{'background'}) {
		err 'No background image.';
	}
	$self->{'i'} = Imager->new(
		'file' => $self->_file($self->{'config'}->{'background'}),
	);
	if (! defined $self->{'i'}) {
		err 'Cannot create background image',
			'Error', Imager->errstr,
	}

	# Get height and width.
	($self->{'width'}, $self->{'height'}) = $self->_size($self->{'i'});

	# Add all buttons.
	foreach my $button_nr ($self->buttons) {
		my $b_hr = $self->{'config'}->{'button'}->{$button_nr};

		# Font file.
		my $font_file;
		if (exists $b_hr->{'font'}->{'file'}
			&& defined $b_hr->{'font'}->{'file'}) {

			$font_file = $self->_file($b_hr->{'font'}->{'file'});
		} elsif (exists $self->{'config'}->{'font'}->{'file'}) {
			$font_file = $self->_file(
				$self->{'config'}->{'font'}->{'file'});
		} else {
			err "No font file for button '$button_nr'.";
		}

		# Font color.
		my $font_color;
		if (exists $b_hr->{'font'}->{'color'}) {
			$font_color = $b_hr->{'font'}->{'color'};
		} elsif (exists $self->{'config'}->{'font'}->{'color'}) {
			$font_color = $self->{'config'}->{'font'}->{'color'};
		} else {
			err "No font color for button '$button_nr'.";
		}

		# Font size.
		my $font_size;
		if (exists $b_hr->{'font'}->{'size'}) {
			$font_size = $b_hr->{'font'}->{'size'};
		} elsif (exists $self->{'config'}->{'font'}->{'size'}) {
			$font_size = $self->{'config'}->{'font'}->{'size'};
		} else {
			err "No font size for button '$button_nr'.";
		}

		# Font object.
		my $font = Imager::Font->new(
			'file' => $font_file,
			'color' => $font_color,
			'size' => $font_size,
		);
		if (! defined $font) {
			err 'Cannot create font object.',
				'Error', Imager->errstr;
		}

		# Get position of string.
		my ($neg_width, $global_descent, $pos_width, $global_ascent,
			$descent, $ascent, $advance_width, $right_bearing)
			= $font->bounding_box(
			'string' => $b_hr->{'text'}->{'string'});

		# X coordinate.
		my $x;
		my $left = 0;
		my $right = $b_hr->{'w'};
		if (exists $b_hr->{'text'}->{'padding'}->{'left'}) {
			$left += $b_hr->{'text'}->{'padding'}->{'left'};
		}
		if (exists $b_hr->{'text'}->{'padding'}->{'right'}) {
			$right -= $b_hr->{'text'}->{'padding'}->{'right'};
		}
		my $width = $right - $left;
		if (exists $b_hr->{'text'}->{'pos'}->{'x'}) {
			$x = $b_hr->{'text'}->{'pos'}->{'x'};
		} elsif (exists $b_hr->{'text'}->{'align'}->{'horz'}
				&& defined $b_hr->{'text'}->{'align'}->{'horz'}) {

			if ($b_hr->{'text'}->{'align'}->{'horz'} eq 'left') {
				$x = $left;
			} elsif ($b_hr->{'text'}->{'align'}->{'horz'} eq 'right') {
				$x = $right - $advance_width;
			}
		}
		if (! defined $x) {
			$x = $width / 2 - $advance_width / 2;
		}

		# Y coordinate.
		my $y;
		my $top = 0;
		my $bottom = $b_hr->{'h'};
		if (exists $b_hr->{'text'}->{'padding'}->{'top'}) {
			$top += $b_hr->{'text'}->{'padding'}->{'top'};
		}
		if (exists $b_hr->{'text'}->{'padding'}->{'bottom'}) {
			$bottom -= $b_hr->{'text'}->{'padding'}->{'bottom'};
		}
		my $height = $bottom - $top;
		if (exists $b_hr->{'text'}->{'pos'}->{'y'}) {
			$y = $b_hr->{'text'}->{'pos'}->{'y'};
		} elsif (exists $b_hr->{'text'}->{'align'}->{'vert'}
			&& defined $b_hr->{'text'}->{'align'}->{'vert'}) {

			if ($b_hr->{'text'}->{'align'}->{'vert'} eq 'top') {
				$y = $top;
			} elsif ($b_hr->{'text'}->{'align'}->{'vert'} eq 'bottom') {
				$y = $height - $global_ascent;
			}
		}
		if (! defined $y) {
			$y = $height / 2 + $global_ascent / 2 + $global_descent / 2;
		}

		# Print string to image.
		my $color = Imager::Color->new($font_color);
		$b_hr->{'imager'}->string(
			'aa' => 1,
			'color' => $color,
			'font' => $font,
			'text' => $b_hr->{'text'}->{'string'},
			'x' => $x,
			'y' => $y,
		);

		# Add image to main image.
		$self->{'i'}->rubthrough(
			'tx' => $b_hr->{'pos'}->{'left'},
			'ty' => $b_hr->{'pos'}->{'top'},
			'src' => $b_hr->{'imager'},
		);
	}

	# Save.
	my $ret = $self->{'i'}->write(
		'file' => $image,
		defined $type ? (
			'type' => $type,
		) : (),
	);
	if (! defined $ret) {
		err "Cannot write file to '$image'.",
			'Error', Imager->errstr;
	}

	return;
}

# Get buttons.
sub _buttons {
	my $self = shift;
	$self->{'buttons'} = [];
	foreach my $button_nr (sort keys %{$self->{'config'}->{'button'}}) {
		if (none { $_ eq $button_nr } @{$self->{'disabled'}}) {
			push @{$self->{'buttons'}}, $button_nr;
		}
	}
	return;
}

# Create button Imager objects.
sub _button_imager {
	my $self = shift;
	foreach my $button_nr ($self->buttons) {
		my $b_hr = $self->{'config'}->{'button'}->{$button_nr};

		# Create imager object for button.
		my $image_path = $self->_file($b_hr->{'image'});
		$b_hr->{'imager'} = Imager->new('file' => $image_path);
		if (! defined $b_hr->{'imager'}) {
			err "Cannot create imager object from ".
				"'$image_path' file.",
				'Error', Imager->errstr;
		}

		# Get width and height.
		($b_hr->{'w'}, $b_hr->{'h'}) = $self->_size($b_hr->{'imager'});
	}
	return;
}

# Config initialization.
sub _config_init {
	my $self = shift;

	# Buttons.
	$self->_buttons;

	# Create imager objects for buttons.
	$self->_button_imager;

	return;
}

# File helper.
sub _file {
	my ($self, $file_value) = @_;
	my $file_path;
	if (defined $self->{'files_dir'}) {
		$file_path = catfile($self->{'files_dir'}, $file_value);
	} else {
		$file_path = $file_value;
	}
	return $file_path;
}

# Get sizes.
sub _size {
	my ($self, $imager) = @_;
	my $width = $imager->getwidth;
	my $height = $imager->getheight;
	return ($width, $height);
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Image::Keyboard - Perl class for image keyboard creating.

=head1 SYNOPSIS

 use Image::Keyboard;
 my $obj = Image::Keyboard->new(%parameters);
 my @button_ids = $obj->buttons;
 my $config_hr = $obj->config($config_hr);
 $obj->image($image, $type);

=head1 METHODS

=over 8

=item C<new(%parameters)>

Constructor.

=over 8

=item * C<config>

 Configuration.
 Default value is undef.

=item * C<disabled>

 Disable buttons.
 Default value is [].

=item * C<files_dir>

 Images directory.
 This variable is used in image() method only.
 Default value is undef.

=back

=item C<buttons()>

 Get buttons ids.
 Return list of buttons ids.

=item C<config($config_hr)>

 Get or set configuration.
 Returns hash reference to configuration structure.

=item C<image($image, $type)>

 Create image.
 Returns undef.

=back

=head1 ERRORS

 new():
         Cannot create imager object from '%s' file.
                 Error: %s
         Parameter 'config' is required.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 config():
         Cannot create imager object from '%s' file.
                 Error: %s

 image():
         Bad files directory '%s'.
         Cannot create background image
                 Error: %s
         Cannot create font object.
                 Error: %s
         Cannot write file to '%s'.
                 Error: %s
         No background image.
         No font color for button '%s'.
         No font file for button '%s'.
         No font size for button '%s'.

=head1 EXAMPLE

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

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<File::Spec::Functions>,
L<Imager>,
L<List::MoreUtils>.

=head1 SEE ALSO

L<Image::Keyboard::Config>,
L<Image::Keyboard::ImageMap::Tags>,
L<Tags>.

=head1 REPOSITORY

L<https://github.com/tupinek/Image-Keyboard>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

BSD license.

=head1 VERSION

0.04

=cut
