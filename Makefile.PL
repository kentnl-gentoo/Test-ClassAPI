require 5.000;
use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'         => 'Test::ClassAPI',
	'VERSION_FROM' => 'lib/Test/ClassAPI.pm',
	'PREREQ_PM'    => {
		File::Spec       => '0.83',
		Test::More       => '0',
		Class::Inspector => '1.05',
		Config::Tiny     => '1.9',
	},
	($] >= 5.005) ? (
		'AUTHOR'   => 'Adam Kennedy (cpan@ali.as)',
		'ABSTRACT' => 'Allows bulk testing of class and method existance in APIs',
	) : (),
);
