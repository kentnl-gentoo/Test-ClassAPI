#!/usr/bin/perl -w

# Testing that the implements command works.
# Also makes sure that =class is actually implicit

use strict;
use lib ();
use File::Spec::Functions qw{:ALL};
BEGIN {
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( catdir( updir(), updir(), 'modules') );
	}
}

use Test::More tests => 17;

# Check their perl version
BEGIN {
	$| = 1;
	ok( $] >= 5.005, "Your perl is new enough" );
}

# Does the module load
use_ok( 'Test::ClassAPI' );

# Run a simple API test, against ourself
Test::ClassAPI->execute('complete', 'collisions');

exit(0);





#####################################################################
# Package to test inheritance

{
	package My::Config;
	sub new          {1}
	sub read         {1}
	sub read_string  {1}
	sub write        {1}
	sub write_string {1}
	sub errstr       {1}
	
	sub foo          {1}

	1;
}

# Config::Tiny is not part of _our_ API, but we do inherit from it,
# so to work, it should be loaded, and anything we define that inherits
# from it should support all of it's methods.

__DATA__

Config::Tiny=interface

[Test::ClassAPI]
init=method
execute=method

[Config::Tiny]
new=method
read=method
read_string=method
write=method
write_string=method
errstr=method

[My::Config]
Config::Tiny=implements
foo=method
