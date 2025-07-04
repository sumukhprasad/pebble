use strict;
use warnings;
use POSIX qw(strftime);
use File::Slurp;

my $now = strftime "%Y-%m-%d %H:%M:%S", localtime;
my $filename = "index.md";

my $content = <<"MD";
# _Assembled File Example_
This post was generated at **$now**.
MD

write_file($filename, $content);

our %config = (
	layout => 'default',
);