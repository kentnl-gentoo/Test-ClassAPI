#!/usr/bin/perl -w

# Formal testing for Test::ClassAPI

use strict;
use File::Spec::Functions qw{:ALL};
use lib catdir( updir(), updir(), 'modules' ), # Development testing
        catdir( updir(), 'lib' );              # Installation testing
use UNIVERSAL 'isa';
use Test::More tests => 2;

# Check their perl version
BEGIN {
	$| = 1;
	ok( $] >= 5.005, "Your perl is new enough" );
}

# Does the module load
use_ok( 'Test::ClassAPI' );

exit(0);
