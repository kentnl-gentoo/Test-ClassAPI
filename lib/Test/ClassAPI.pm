package Test::ClassAPI;

# Allows us to test class APIs in a simplified manner.
# Implemented as a wrapper around Test::More, Class::Inspector and Config::Tiny.

use strict;
use UNIVERSAL 'isa';
use Config::Tiny;
use Class::Inspector;
BEGIN {
	$Test::ClassAPI::VERSION = 0.1;
	require Test::More;
}





# Globals
use vars qw{$Config $executed};
BEGIN {
	# Start with the Config empty
	$Config = undef;

	# Because we set up the number of tests, we can only execute once
	$executed = 0;
}





#####################################################################
# Main Methods

# Initialise the Config variable
sub init {
	my $class = shift;

	# Get the file to use
	*Test::ClassAPI::DATA = ( @_ and isa($_[0], 'GLOB') )
		? shift : *main::DATA;

	# Read in all the data
	my $contents;
	{
		local $/ = undef;
		$contents = <DATA>;
	}

	# Create the config object
	$Config = Config::Tiny->read_string( $contents );
	unless ( $Config ) {
		die "Failed to load test configuration: "
			. Config::Tiny->errstr;
	}

	return 1;
}

# Find the number of tests we will have to execute
sub tests {
	my $class = shift;
	$class->init unless $Config;

	# Count up the total number of first level keys,
	# excluding the root section underscore key,
	# and add all the second level keys.
	my $count = scalar grep { $_ ne '_' } keys %$Config;
	foreach my $section ( values %$Config ) {
		$count += scalar keys %$section;
	}

	return $count;
}




# Execute the tests.
# All tests are done in alphabetical order
sub execute {
	my $class = shift;
	die "You can only execute once, use another test script, or merge your configs" if $executed;
	$class->init unless $Config;

	# Check how many tests
	my $tests = $class->tests;
	die "Config contains no tests" unless $tests;

	# Using the test count, set up the schedule
	Test::More->import( tests => $tests );

	# First execute the root tests
	### COMPLETE THIS

	# Next, check all the classes are loaded
	my @class_list = grep { $_ ne '_' } sort keys %$Config;
	foreach my $class ( @class_list ) {
		# Is the class loaded
		ok( Class::Inspector->loaded( $class ), "Class '$class' is loaded" );
	}

	# Next, check the remaining tests for each class
	foreach my $class ( @class_list ) {
		# Now check each of the methods ( as methods )
		foreach my $name ( sort keys %{$Config->{$class}} ) {
			my $type = $Config->{$class}->{$name};
			if ( $type eq 'method' ) {
				can_ok( $class, $name );
			} elsif ( $type eq 'isa' ) {
				ok( isa($class, $name), "$class->isa('$name');" );
			}
		}
	}

	return 1;
}






1;

__END__

=head1 NAME - Test::ClassAPI

Don't use this yet, the API definition language is CRAP...

I need it uploaded for PPI tests...

=head1 TO DO

Lots of stuff

=head2 SUPPORT

None. Don't use this for anything you don't want to have to rewrite.

=head1 AUTHOR

    Adam Kennedy
    cpan@ali.as
    http//ali.as/

=head1 COPYRIGHT

opyright (c) 2002-2003 Adam Kennedy. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
