package Test::ClassAPI;

# Allows us to test class APIs in a simplified manner.
# Implemented as a wrapper around Test::More, Class::Inspector and Config::Tiny.

use strict;
use UNIVERSAL 'isa';
use Test::More       ();
use Class::ISA       ();
use Config::Tiny     ();
use Class::Inspector ();

use vars qw{$VERSION $CONFIG $SCHEDULE $EXECUTED %IGNORE *DATA};
BEGIN {
	$VERSION = '0.5';

	# Config starts empty
	$CONFIG   = undef;
	$SCHEDULE = undef;

	# We only execute once
	$EXECUTED = '';

	# When looking for method that arn't described in the class
	# description, we ignore anything from UNIVERSAL.
	%IGNORE = map { $_, 1 } qw{isa can VERSION};
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

	# Handle options
	my $CHECK_UNKNOWN_METHODS = !! scalar(grep { lc $_ eq 'complete'} @_);

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
		my %known_methods = ();
		foreach my $parent ( @path ) {
			foreach my $test ( keys %{$CONFIG->{$parent}} ) {
				my $type = $CONFIG->{$parent}->{$test};
				if ( $type eq 'method' ) {
					# Does the class have a method
					$known_methods{$test}++;
					Test::More::can_ok( $class, $test );
				} elsif ( $type eq 'isa' ) {
					# Does the class inherit from a parent
					Test::More::ok( isa( $class, $test ), "$class isa $test" );
				}
			}
		}

		next unless $CHECK_UNKNOWN_METHODS;

		# Check for unknown public methods
		my $methods = Class::Inspector->methods( $class, 'public' )
			or die "Failed to find public methods for class '$class'";
		@$methods = grep { ! ($IGNORE{$_} or $known_methods{$_}) } @$methods;
		if ( @$methods ) {
			print STDERR join '', map { "# Found undocumented method '$_'\n" } @$methods;
		}
		Test::More::is( scalar(@$methods), 0, "No unknown public methods in '$class'" );
	}

	1;
}

1;

__END__

=head1 NAME

Test::ClassAPI - Provides basic first-pass API testing for large class trees

=head1 DESCRIPTION

For many APIs with large numbers of classes, it can be very useful to be able
to do a quick once-over to make sure that classes, methods, and inheritance
is correct, before doing more comprehensive testing. This module aims to provide
such a capability.

=head2 Using Test::ClassAPI

Test::ClassAPI is used with a fairly standard looking test script, with the
API description contained in a __DATA__ section at the end of the script.

  #!/usr/bin/perl
  
  # Test the API for Foo::Bar
  use strict;
  use Test::More 'tests' => 123; # Optional
  use Test::ClassAPI;
  
  # Load the API to test
  use Foo::Bar;
  
  # Execute the tests
  Test::ClassAPI->execute;
  
  __DATA__
  
  Foo::Bar::Thing=interface
  Foo::Bar::Object=abstract
  Foo::Bar::Planet=class
  
  [Foo::Bar::Thing]
  foo=method
  
  [Foo::Bar::Object]
  bar=method
  whatsit=method
  
  [Foo::Bar::Planet]
  Foo::Bar::Object=isa
  Foo::Bar::Thing=isa
  blow_up=method
  freeze=method
  thaw=method

Looking at the test script, the code itself is fairly simple. We first load
Test::More and Test::ClassAPI. The loading and specification of a test plan
is optional, Test::ClassAPI will provide a plan automatically if needed.

This is followed by a compulsory __DATA__ section, containing the API
description. This description is in provided in the general form of a Windows
style .ini file and is structured as follows.

=head2 Class Manifest

At the beginning of the file, in the root section of the config file, is a
list of entries where the key represents a class name, and the value is one
of either 'class', 'abstract', or 'interface'.

The 'class' entry indicates a fully fledged class. That is, the class is
tested to ensure it has been loaded, and the existance of every method listed
in the section ( and it's superclasses ) is tested for.

The 'abstract' entry indicates an abstract class, one which is part of our
class tree, and needs to exist, but is never instantiated directly, and thus
does not have to itself implement all of the methods listed for it. Generally,
many individual 'class' entries will inherit from an 'abstract', and thus a
method listed in the abstract's section will be tested for in all the 
subclasses of it.

The 'interface' entry indicates an external interface that is not part of
our class tree, but is inherited from by one or more of our classes, and thus
the methods listed in the interface's section are tested for in all the 
classes that inherit from it. For example, if a class inherits from, and
implements, the File::Handle interface, a C<File::Handle=interface> entry
could be added, with the C<[File::Handle]> section listing all the methods
in File::Handle that our class tree actually cares about. No tests, for class
or method existance, are done on the interface itself.

=head2 Class Sections

Every class listed in the class manifest B<MUST> have an individual section,
indicated by C<[Class::Name]> and containing a set of entries where the key
is the name of something to test, and the value is the type of test for it.

The 'isa' test checks inheritance, to make sure that the class the section is
for is (by some path) a sub-class of something else. This does not have to be
an immediate sub-class. Any class refered to (recursively) in a 'isa' test
will have it's 'method' test entries applied to the class as well.

The 'method' test is a simple method existance test, using C<UNIVERSAL::can>
to make sure that the method exists in the class.

=head1 METHODS

=head2 execute

The C<Test::ClassAPI> has a single method, C<execute> which is used to start
the testing process. It accepts a single option argument, 'complete', which
indicates to the testing process that the API listed should be considered a
complete list of the entire API. This enables an additional test for each
class to ensure that B<every> public method in the class is detailed in the
API description, and that nothing has been "missed".

=head2 SUPPORT

Bugs should be submitted via the CPAN bug tracker, located at

  http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test%3A%3AClassAPI

For other issues, contact the author

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
