package Pebble::Config;

use strict;
use warnings;

sub load_config {
	my ($path) = @_;
	my %config;

	my $assemble = "$path/config-assemble.pl";
	my $hash	 = "$path/config.pl";

	if (-e $assemble) {
		print "Found config-assemble for $path, running...\n";
		do $assemble;
		%config = %main::config;
	}
	elsif (-e $hash) {
		print "Loading config for $path...\n";
		do $hash;
		%config = %main::config;
	}
	else {
		print "No config for $path, using defaults.\n";
		%config = ();
	}

	return \%config;
}

1;