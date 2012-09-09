package Image::Keyboard;

# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Utils qw(set_params);
use Encode qw(decode_utf8);
use Error::Pure qw(err);
use File::Spec::Functions qw(catfile);
use HTML::Entities;
use Imager;
use List::MoreUtils qw(none);

# Version.
our $VERSION = 0.01;

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

	# Check images directory.
	if (! -d $self->{'files_dir'}) {
		err "Bad files directory '$self->{'files_dir'}'.";
	}

	# Config initialization.
	$self->_config_init;

	# Object.
	return $self;
}

# Get buttons count.
sub buttons {
	my $self = shift;
	return @{$self->{'buttons'}};
}

# Get or set configuration.
sub config {
	my ($self, $config_hr) = @_;
	if ($config_hr) {
		$self->{'config'} = $config_hr;
		$self->_config_init;
	}
	return $self->{'config'};
}

# Create image.
sub image {
	my ($self, $image, $type) = @_;

	# Create image.
	if (! $self->{'config'}->{'background'}) {
		err 'No background image.';
	}
	$self->{'i'} = Imager->new(
		'file' => catfile($self->{'files_dir'},
			$self->{'config'}->{'background'}),
	);
	if (! defined $self->{'i'}) {
		err 'Cannot create background image',
			'Error', Imager->errstr,
	}

	# Get height and width.
	($self->{'width'}, $self->{'height'}) = $self->_size($self->{'i'});

	# Add all buttons.
	foreach my $button_nr (@{$self->{'buttons'}}) {
		my $b_hr = $self->{'config'}->{'button'}->{$button_nr};
		
		# Add text.
		my $font_file;
		if (exists $b_hr->{'font'}->{'file'}) {
			$font_file = catfile($self->{'files_dir'},
				$b_hr->{'font'}->{'file'});
		} elsif (exists $self->{'config'}->{'font'}->{'file'}) {
			$font_file = catfile($self->{'files_dir'},
				$self->{'config'}->{'font'}->{'file'});
		} else {
			err "No font file for button '$button_nr'.";
		}
		my $font_color;
		if (exists $b_hr->{'font'}->{'color'}) {
			$font_color = $b_hr->{'font'}->{'color'};
		} elsif (exists $self->{'config'}->{'font'}->{'color'}) {
			$font_color = $self->{'config'}->{'font'}->{'color'};
		} else {
			err "No font color for button '$button_nr'.";
		}
		my $font_size;
		if (exists $b_hr->{'font'}->{'size'}) {
			$font_size = $b_hr->{'font'}->{'size'};
		} elsif (exists $self->{'config'}->{'font'}->{'size'}) {
			$font_size = $self->{'config'}->{'font'}->{'size'};
		} else {
			err "No font size for button '$button_nr'.";
		}
		my $font = Imager::Font->new(
			'file' => $font_file,
			'color' => $font_color,
			'size' => $font_size,
		);
		if (! defined $font) {
			err 'Cannot create font object.',
				'Error', Imager->errstr;
		}
		my $color = Imager::Color->new($font_color);
		my ($neg_width, $global_descent, $pos_width, $global_ascent,
			$descent, $ascent, $advance_width, $right_bearing)
			= $font->bounding_box(
			'string' => $b_hr->{'text'}->{'string'});
		my $x;
		if (exists $b_hr->{'text'}->{'pos'}->{'x'}) {
			$x = $b_hr->{'text'}->{'pos'}->{'x'};
		} else {
			$x = $b_hr->{'w'} / 2 - $advance_width / 2;
		}
		my $y;
		if (exists $b_hr->{'text'}->{'pos'}->{'y'}) {
			$y = $b_hr->{'text'}->{'pos'}->{'y'};
		} else {
			$y = $b_hr->{'h'} / 2 + $ascent / 2;
		}
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

# Get image map.
sub imagemap {
	my ($self, $usemap) = @_;
	if (! defined $usemap) {
		$usemap = 'keyboard';
	}
	my @image_map = (
		['b', 'map'],
		['a', 'name', $usemap],
	);
	foreach my $button_nr ($self->buttons) {
		my $b_hr = $self->{'config'}->{'button'}->{$button_nr};
		my $left = $b_hr->{'pos'}->{'left'};
		my $top = $b_hr->{'pos'}->{'top'};
		my $coords = join ',', ($left, $top, $left + $b_hr->{'w'},
			$top + $b_hr->{'h'});
		my $string = $b_hr->{'text'}->{'string'};
		my $enc_string = $self->_encode_js($string);
		push @image_map, (
			['b', 'area'],
			['a', 'id', 'button_'.$button_nr],
			['a', 'shape', 'rect'],
			['a', 'coords', $coords],
			['a', 'onClick', "keyboard_click('$enc_string');"],
			['e', 'area'],
		);
	}
	push @image_map, (
		['e', 'map'],
	);
	return @image_map;
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
		my $image_path = catfile($self->{'files_dir'},
			$b_hr->{'image'});
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

# Encode values for js.
sub _encode_js {
	my ($self, $value) = @_;
	if ($value eq decode_utf8('←')) {
		$value = 'Backspace';
	} elsif ($value eq decode_utf8('°')) {
		$value = 'Ring';
	} elsif ($value eq decode_utf8('ˇ')) {
		$value = 'Caron';
	} elsif ($value eq decode_utf8('¨')) {
		$value = 'Diaeresis';
	} elsif ($value eq decode_utf8('\'')) {
		$value = 'Apostrophe';
	} elsif ($value eq decode_utf8('´')) {
		$value = 'Acute_accent';
	} elsif ($value eq '\\') {
		$value = '\\\\';
	}
	my $enc_value = encode_entities($value);
	$value = $enc_value;
	return $value;
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

