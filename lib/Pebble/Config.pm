package Pebble::Config;

use strict;
use warnings;
use Cwd;
use File::Spec;

sub load_config {
	my ($path) = @_;
	my %config;

	my $assemble = File::Spec->catfile($path, 'config-assemble.pl');
	my $hash	 = File::Spec->catfile($path, 'config.pl');

	if (-e $assemble) {
		print "Found config-assemble for $path, running...\n";

		my $original_dir = getcwd();
		chdir $path or die "Couldn't chdir to $path: $!";
		
		%main::config = ();

		do './config-assemble.pl';
		if ($@) { die "Error running config-assemble.pl: $@"; }

		%config = %main::config;

		chdir $original_dir or die "Couldn't return to original dir: $!";
	}
	elsif (-e $hash) {
		print "Loading config for $path...\n";

		%main::config = ();
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