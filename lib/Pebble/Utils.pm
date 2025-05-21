package Pebble::Utils;

use strict;
use warnings;
use Exporter 'import';
use Cwd;
use File::Spec;
use File::Path qw(remove_tree);
use File::Temp qw(tempdir);
use File::Copy::Recursive qw(dircopy);

our @EXPORT_OK = qw(run_with_temp_restore);

sub run_with_temp_restore {
	my ($target_dir, $code_ref, $post_code_ref) = @_;
	
	die "Missing directory path" unless $target_dir;
	die "Second argument must be a coderef" unless ref($code_ref) eq 'CODE';
	die "Third argument must be a coderef" unless ref($post_code_ref) eq 'CODE';

	print "Creating temp backup of $target_dir...\n";

	my $temp_dir = tempdir(CLEANUP => 0);

	dircopy($target_dir, $temp_dir)
		or die "Failed to copy $target_dir to $temp_dir: $!";

	my $original_dir = getcwd();

	print "Running code block...\n";

	eval {
		$code_ref->();
		1;
	} or do {
		my $err = $@ || "unknown error";
		die "Error during code block execution: $err\n";
	};

	print "Restoring original directory contents...\n";

	remove_tree($target_dir, { keep_root => 1 }) 
		or warn "Could not clear $target_dir: $!";

	dircopy($temp_dir, $target_dir)
		or warn "Could not restore from temp: $!";
	
	eval {
		$post_code_ref->();
		1;
	} or do {
		my $err = $@ || "unknown error";
		die "Error during code block execution: $err\n";
	};
	
	print "Cleaning up temp folder...\n";
	remove_tree($temp_dir);
}

1;
