package Test::ClassAPI;

# Allows us to test class APIs in a simplified manner.
# Implemented as a wrapper around Test::More, Class::Inspector and Config::Tiny.

use strict;
use UNIVERSAL 'isa';
use Test::More       ();
use Class::ISA       ();
use Config::Tiny     ();
use Class::Inspector ();

use vars qw{$VERSION $CONFIG $SCHEDULE $EXECUTED *DATA};
BEGIN {
	$VERSION = '0.3';

	# Config starts empty
	$CONFIG   = undef;
	$SCHEDULE = undef;

	# We can only execute one
	$EXECUTED = '';
}





#####################################################################
# Main Methods

# Initialise the Configuration
sub init {
	my $class = shift;

	# Use the script's DATA handle or one passed
	*DATA = isa( $_[0], 'GLOB' ) ? shift : *main::DATA;
 
	# Read in all the data, and create the config object
	local $/ = undef;
	$CONFIG = Config::Tiny->read_string( <DATA> )
		or die 'Failed to load test configuration: '
			. Config::Tiny->errstr;

	# Check for a schedule, and it's structure
	$SCHEDULE = delete $CONFIG->{_}
		or die 'Config does not have a schedule defined';
	foreach my $class ( keys %$SCHEDULE ) {
		my $value = $SCHEDULE->{$class};
		unless ( $value =~ /^(?:class|abstract|interface)$/ ) {
			die "Invalid schedule option '$value' for class '$class'";
		}
		unless ( $CONFIG->{$class} ) {
			die "No section '[$class]' defined for schedule class";
		}
	}

	1;
}

# Find and execute the tests
sub execute {
	my $class = shift;
	if ( $EXECUTED ) {
		die 'You can only execute once, use another test script';
	}
	$class->init unless $CONFIG;

	# Set the plan of no plan if we don't have a plan
	unless ( Test::More->builder->has_plan ) {
		Test::More::plan( 'no_plan' );
	}

	# Determine the list of classes to test
	my @classes = sort keys %$SCHEDULE;
	@classes = grep { $SCHEDULE->{$_} ne 'interface' } @classes;

	# Check that all the classes/abstracts are loaded
	foreach my $class ( @classes ) {
		Test::More::ok( Class::Inspector->loaded( $class ), "Class '$class' is loaded" );
	}

	# Check that all the full classes match all the required interfaces
	@classes = grep { $SCHEDULE->{$_} eq 'class' } @classes;
	foreach my $class ( @classes ) {
		# Find all testable parents
		my @path = ($class, Class::ISA::super_path($class));
		@path = grep { $SCHEDULE->{$_} } @path;

		# Iterate over the testable entries
		foreach my $parent ( @path ) {
			# Find the methods to test
			my @methods = keys %{$CONFIG->{$parent}};
			@methods = grep { $CONFIG->{$parent}->{$_} eq 'method' } @methods;

			# Test each of the methods
			foreach my $method ( @methods ) {
				Test::More::can_ok( $class, $method );
			}
		}
	}

	1;
}

1;

__END__

=head1 NAME

Test::ClassAPI - Basic class and method existance testing for large scale APIs

=head1 DESCRIPTION

Don't use this yet, the API definition language is CRAP...

I need it uploaded for PPI tests...

=head1 TO DO

Lots of stuff

=head2 SUPPORT

None. Don't use this for anything you don't want to have to rewrite.

=head1 AUTHOR

    Adam Kennedy (Maintainer)
    cpan@ali.as
    http//ali.as/

=head1 COPYRIGHT

opyright (c) 2002-2004 Adam Kennedy. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
