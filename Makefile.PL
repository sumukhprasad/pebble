use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME	=> 'Pebble',
	VERSION => '0.01',
	AUTHOR => 'Sumukh Prasad',
	ABSTRACT => 'Tiny static site generator written in Perl.',
	LICENSE => 'perl',
	EXE_FILES	=> ['bin/pebble'],
	PREREQ_PM	=> {
		'File::Find' => 0,
		'File::Path' => 0,
		'File::Basename' => 0,
		'File::Slurp' => 0,
		'Cwd' => 0,
		'Text::Markdown' => 0,
		'Getopt::Long' => 0,
	},
	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'https://github.com/sumukhprasad/pebble.git',
				web  => 'https://github.com/sumukhprasad/pebble',
			},
		},
	},
);