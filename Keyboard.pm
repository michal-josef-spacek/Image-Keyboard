package Image::Keyboard;

# Pragmas.
use strict;
use warnings;

# Modules.
use Class::Utils qw(set_params);
use Config::Dot;
use Error::Pure qw(err);
use File::Spec::Functions qw(catfile);
use Imager;
use Perl6::Slurp qw(slurp);

# Version.
our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Images directory.
	$self->{'files_dir'} = undef;

	# Process params.
	set_params($self, @params);

	# Check images directory.
	if (! -d $self->{'files_dir'}) {
		err "Bad files directory '$self->{'files_dir'}'.";
	}

	# Object.
	return $self;
}

# Create image.
sub image {
	my ($self, $image, $config_file) = @_;
	
	# Process config.
	my $config = slurp($config_file);
	my $c = Config::Dot->new;
	my $c_hr = $c->parse($config);

	# Create image.
	if (! $c_hr->{'background'}) {
		err 'No background image.';
	}
	$self->{'i'} = Imager->new(
		'file' => catfile($self->{'files_dir'}, $c_hr->{'background'}),
	);
	if (! defined $self->{'i'}) {
		err 'Cannot create background image',
			'Error', Imager->errstr,
	}

	# Get height and width.
	($self->{'width'}, $self->{'height'}) = $self->_size($self->{'i'});

	# Add all buttons.
	foreach my $button_nr (sort keys %{$c_hr->{'button'}}) {
		my $b_hr = $c_hr->{'button'}->{$button_nr};
		my $image_path = catfile($self->{'files_dir'},
			$b_hr->{'image'});
		my $i = Imager->new('file' => $image_path);
		if (! defined $i) {
			err "Cannot create image '$image_path' object.",
				'Error', Imager->errstr;
		}
		
		# Add text.
		my $font_file;
		if (exists $b_hr->{'font'}->{'file'}) {
			$font_file = catfile($self->{'files_dir'},
				$b_hr->{'font'}->{'file'});
		} elsif (exists $c_hr->{'font'}->{'file'}) {
			$font_file = catfile($self->{'files_dir'},
				$c_hr->{'font'}->{'file'});
		} else {
			err "No font file for button '$button_nr'.";
		}
		my $font_color;
		if (exists $b_hr->{'font'}->{'color'}) {
			$font_color = $b_hr->{'font'}->{'color'};
		} elsif (exists $c_hr->{'font'}->{'color'}) {
			$font_color = $c_hr->{'font'}->{'color'};
		} else {
			err "No font color for button '$button_nr'.";
		}
		my $font_size;
		if (exists $b_hr->{'font'}->{'size'}) {
			$font_size = $b_hr->{'font'}->{'size'};
		} elsif (exists $c_hr->{'font'}->{'size'}) {
			$font_size = $c_hr->{'font'}->{'size'};
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
		my ($w, $h) = $self->_size($i);
		my $color = Imager::Color->new($font_color);
		my ($neg_width, $global_descent, $pos_width, $global_ascent,
			$descent, $ascent, $advance_width, $right_bearing)
			= $font->bounding_box(
			'string' => $b_hr->{'text'}->{'string'});
		my $x;
		if (exists $b_hr->{'text'}->{'pos'}->{'x'}) {
			$x = $b_hr->{'text'}->{'pos'}->{'x'};
		} else {
			$x = $w / 2 - $advance_width / 2;
		}
		my $y;
		if (exists $b_hr->{'text'}->{'pos'}->{'y'}) {
			$y = $b_hr->{'text'}->{'pos'}->{'y'};
		} else {
			$y = $h / 2 + $ascent / 2;
		}
		$i->string(
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
			'src' => $i,
		);
	}

	# Save.
	$self->{'i'}->write('file' => $image);

	return;
}

# Get image map.
sub imagemap {
	my $self = shift;
	my $image_map = '';
	# TODO
	return $image_map;
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

