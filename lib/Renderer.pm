package Pebble::Renderer;

use strict;
use warnings;
use File::Basename;
use Text::Markdown 'markdown';
use File::Path 'make_path';
use File::Slurp;

sub render_markdown {
	my ($md_file, $site_dir, $output_dir, $config) = @_;

	my $content = read_file($md_file);
	my $html = markdown($content);

	my $layout = $config->{layout} || 'default';
	my $layout_path = "$site_dir/_layouts/$layout.html";

	my $final_html;
	if (-e $layout_path) {
		my $layout_tpl = read_file($layout_path);
		$layout_tpl =~ s/\{\{\s*content\s*\}\}/$html/;
		$final_html = $layout_tpl;
	} else {
		$final_html = $html;
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