#!/usr/bin/perl -w

# Self-API testing for Test::ClassAPI

use strict;
use lib ();
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( catdir( updir(), updir(), 'modules') );
	}
}

use Test::More tests => 15;

# Run a simple API test, against ourself
use_ok( 'Test::ClassAPI' );
Test::ClassAPI->execute('complete');

exit(0);





#####################################################################
# Package to test inheritance

{
	package My::Config;	
	use base 'Config::Tiny';
	sub foo { 1 }
	1;
}

# Config::Tiny is not part of _our_ API, but we do inherit from it,
# so to work, it should be loaded, and anything we define that inherits
# from it should support all of it's methods.

__DATA__

Test::ClassAPI=class
Config::Tiny=interface
My::Config=class

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
Config::Tiny=isa
foo=method
