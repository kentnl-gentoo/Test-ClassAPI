#!/usr/bin/perl -w

# Self-API testing for Test::ClassAPI

use strict;
use File::Spec::Functions qw{:ALL};
use lib catdir( updir(), updir(), 'modules' ), # Development testing
        catdir( updir(), 'lib' );              # Installation testing
use UNIVERSAL 'isa';
# BEGIN { $DB::single = $DB::single = 1 }
use Test::More tests => 16;

# Check their perl version
BEGIN {
	$| = 1;
	ok( $] >= 5.005, "Your perl is new enough" );
}

# Does the module load
use_ok( 'Test::ClassAPI' );

# Run a simple API test, against ourself
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
