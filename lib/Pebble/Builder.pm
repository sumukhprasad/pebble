package Pebble::Builder;

use strict;
use warnings;
use File::Find;
use File::Path qw(make_path remove_tree);
use File::Basename;
use File::Copy::Recursive qw(dircopy);
use Cwd 'abs_path';
use Data::GUID qw(guid_string);

use Pebble::Config;
use Pebble::Renderer;


use Pebble::Utils qw(run_with_temp_restore);

sub build {
	my ($site_dir, $output_dir) = @_;
	my $temp_output = "/tmp/" . guid_string();
	
	run_with_temp_restore($site_dir, sub {
		build_meta($site_dir, $output_dir, $temp_output);
	}, sub {
		dircopy($temp_output, $output_dir) or die "Failed to copy build to $output_dir: $!";
	});
}

sub build_meta {
	my ($site_dir, $output_dir, $temp_output) = @_;
	$site_dir = abs_path($site_dir);
	
	make_path($temp_output);

	make_path($output_dir);

	print "Building site in $site_dir...\n";
	
	opendir(my $dh, $site_dir) or die "can't open $site_dir: $!";
	my %reserved = map { $_ => 1 } qw(_site _layouts _includes _sass);

	my @entries = grep {
		$_ !~ /^\./ && !$reserved{$_}
	} readdir($dh);
	closedir($dh);

	print "Processing root directory...\n";
	my $root_config = Pebble::Config::load_config($site_dir);
	my @root_md_files;

	find(sub {
		return unless /\.md$/;
		return unless -f $_;
		
		my $rel = $File::Find::name;
		$rel =~ s/\Q$site_dir\E\/?//;
		return if $rel =~ /\//;
		push @root_md_files, $File::Find::name;
	}, $site_dir);

	for my $md_file (@root_md_files) {
		Pebble::Renderer::render_markdown($md_file, $site_dir, $temp_output, $root_config);
	}

	for my $entry (@entries) {
		my $path = "$site_dir/$entry";
		next unless -d $path;

		print "Processing $entry...\n";

		my $config = Pebble::Config::load_config($path);
		my @markdown_files;

		find(sub {
			return unless /\.md$/;
			push @markdown_files, $File::Find::name;
		}, $path);
	
		for my $md_file (@markdown_files) {
			Pebble::Renderer::render_markdown($md_file, $site_dir, $temp_output, $config);
		}
	}

	remove_tree($output_dir, { keep_root => 1 });

	print "Done!\n";
}

1;
