package Pebble::Config;

use strict;
use warnings;
use Cwd;
use File::Spec;
use YAML::Tiny;

sub load_config {
	my ($path) = @_;
	my %config;

	my $assemble = File::Spec->catfile($path, 'config-assemble.pl');
	my $yaml;
	for my $ext (qw(yml yaml)) {
		my $try = File::Spec->catfile($path, "config.$ext");
		if (-e $try) {
			$yaml = $try;
			last;
		}
	}

	if (-e $assemble) {
		print "Found config-assemble for $path, running...\n";

		my $original_dir = getcwd();
		chdir $path or die "Couldn't chdir to $path: $!\n";
		
		%main::config = ();

		do './config-assemble.pl';
		if ($@) { die "Error running config-assemble.pl: $@\n"; }

		%config = %main::config;

		chdir $original_dir or die "Couldn't return to original dir: $!\n";
	}
	elsif (-e $yaml) {
		print "Loading config from YAML for $path...\n";

		my $yaml_obj = YAML::Tiny->read($yaml)
			or die "Couldn't read $yaml: $YAML::Tiny::errstr";
			
		%config = %{ $yaml_obj->[0] };
	}
	else {
		print "No config for $path, using defaults.\n";
		%config = ();
	}
	

	return \%config;
}

1;