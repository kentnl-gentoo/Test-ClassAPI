require 5.000;
use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'         => 'Test::ClassAPI',
	'VERSION_FROM' => 'lib/Test/ClassAPI.pm',
	'PREREQ_PM'    => {
		Test::More       => 0,
		Config::Tiny     => 1.0,
		Class::Inspector => 1.0,
	},
	($] >= 5.005) ? (
		'AUTHOR'   => 'Adam Kennedy (cpan@ali.as)',
		'ABSTRACT' => 'Allow bulk testing of class and method existance in APIs',
	) : (),
);
