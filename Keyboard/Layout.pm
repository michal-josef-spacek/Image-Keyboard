package Image::Keyboard::Layout;

use strict;
use warnings;

use Class::Utils qw(set_params);

our $VERSION = 0.04;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Layout.
	$self->{'layout'} = {};

	# Process params.
	set_params($self, @params);

	# Object.
	return $self;
}

# Get sorted layout ids.
sub ids {
	my $self = shift;
	return sort keys %{$self->{'layout'}};	
}

# Get value for layout id.
sub value {
	my ($self, $key) = @_;
	if (exists $self->{'layout'}->{$key}) {
		return $self->{'layout'}->{$key};
	} else {
		return;
	}
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Image::Keyboard::Layout - Perl class for keyboard layouts.

=head1 SYNOPSIS

 use Image::Keyboard::Layout;

 my $layout = Image::Keyboard::Layout->new(%parameters);
 my @ids = $layout->ids;
 my $value = $layout->value($key);

=head1 METHODS

=head2 C<new>

 my $layout = Image::Keyboard::Layout->new(%parameters);

Constructor.

=over 8

=item * B<layout>

 Reference to hash with layout definition.
 Default value is {}.

=back

=head2 C<ids>

 my @ids = $layout->ids;

Gets all layout ids.

Returns sorted array of ids.

=head2 C<value>

 my $value = $layout->value($key);

Gets layout value for id.

Returns scalar string.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE

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

=head1 DEPENDENCIES

L<Class::Utils>.

=head1 SEE ALSO

L<Image::Keyboard>,
L<Image::Keyboard::Button>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Image-Keyboard>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

BSD license.

=head1 VERSION

0.04

=cut
