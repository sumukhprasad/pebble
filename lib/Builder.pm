package Pebble::Builder;

use strict;
use warnings;
use File::Find;
use File::Path qw(make_path);
use File::Basename;
use Cwd 'abs_path';

sub build {
	my $site_dir = @_;
	my $output_dir = "$site_dir/_site";
	
	make_path($output_dir);
	
	
	
	print "Starting build..."
	
	opendir(my $dh, $site_dir) or die "can't open $site_dir: $!";
	my @entries = grep { !/^\.|_site/ } readdir($dh);
	closedir($dh);
	
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
	 
	 print "Built.\n";
}

1;