use lib '.';
use strict;
use warnings;

use inc::Module::Install;

# Definition.
abstract 'Perl class for image keyboard creating.';
author 'Michal Josef Spacek <skim@cpan.org>';
author_requires 'English' => 0;
author_requires 'File::Object' => 0.05;
author_requires 'Test::More' => 0;
author_requires 'Test::NoWarnings' => 0;
author_requires 'Test::Pod' => 0;
author_requires 'Test::Pod::Coverage' => 0;
license 'bsd';
name 'Image-Keyboard';
readme_from 'Keyboard.pm';
recursive_author_tests('xt');
requires 'Class::Utils' => 0.03;
requires 'Encode' => 0;
requires 'Error::Pure' => 0.11;
requires 'File::Spec::Functions' => 0;
requires 'HTML::Entities' => 0;
requires 'Imager' => 0;
requires 'List::Util' => 1.33;
requires 'perl' => '5.6.2';
resources 'bugtracker' => 'https://rt.cpan.org/Public/Dist/Display.html'.
	'?Name=Image-Keyboard';
resources 'homepage' => 'https://github.com/michal-josef-spacek/Image-Keyboard';
resources 'repository' => 'git://github.com/michal-josef-spacek/Image-Keyboard';
test_requires 'Test::More' => 0;
test_requires 'Test::NoWarnings' => 0;
tests_recursive;
version '0.04';

# Run.
WriteAll();
