package Pebble::Builder;

use strict;
use warnings;
use File::Find;
use File::Path qw(make_path);
use File::Basename;
use Cwd 'abs_path';

use Pebble::Config;
use Pebble::Renderer;

sub build {
	my ($site_dir) = @_;
	$site_dir = abs_path($site_dir);
	my $output_dir = "$site_dir/_site";
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
		 Pebble::Renderer::render_markdown($md_file, $site_dir, $output_dir, $root_config);
	}
	
	
	for my $entry (@entries) {
		my $path = "$site_dir/$entry";
		next unless -d $path;
	
		my $config = Pebble::Config::load_config($path);
		my @markdown_files;
	
		find(sub {
			return unless /\.md$/;
			push @markdown_files, $File::Find::name;
		}, $path);
	
		for my $md_file (@markdown_files) {
			Pebble::Renderer::render_markdown($md_file, $site_dir, $output_dir, $config);
		}
	}
	
	print "Done!\n";
}

1;