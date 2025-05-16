package Pebble::Renderer;

use strict;
use warnings;
use File::Basename;
use Text::Markdown 'markdown';
use File::Path 'make_path';
use File::Slurp;

sub render_markdown {
	my ($md_file, $site_dir, $output_dir, $default_config) = @_;

	my $raw = read_file($md_file);

	my %frontmatter;
	my $body = $raw;

	if ($raw =~ /^---\s*\n(.*?)\n---\s*\n(.*)/s) {
		my $header = $1;
		$body = $2;

		for my $line (split /\n/, $header) {
			if ($line =~ /^\s*(\w+)\s*:\s*(.+?)\s*$/) {
				$frontmatter{$1} = $2;
			}
		}
	}

	my $html = markdown($body);

	my $layout = $frontmatter{layout} || $default_config->{layout} || 'default';
	my $layout_path = "$site_dir/_layouts/$layout.html";
	
	my $final_html = $html;

	if (-e $layout_path) {
		my $layout_tpl = read_file($layout_path);

		$layout_tpl =~ s/\{\{\s*content\s*\}\}/$html/g;

		for my $key (keys %frontmatter) {
			my $val = $frontmatter{$key};
			$layout_tpl =~ s/\{\{\s*$key\s*\}\}/$val/g;
		}

		$final_html = $layout_tpl;
	}

	my $out_path = $md_file;
	$out_path =~ s/\Q$site_dir\E//;
	$out_path =~ s/\.md$/.html/;
	$out_path = "$output_dir/$out_path";

	my $out_dir = dirname($out_path);
	make_path($out_dir);
	write_file($out_path, $final_html);

	print "Rendered: $out_path\n";
}

1;