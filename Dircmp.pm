# Copyright (c) 2003 Josh Schulte. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

package File::Dircmp;

require Exporter;

@ISA = "Exporter";
@EXPORT = qw(dircmp);

use File::Basename;
use File::Glob "bsd_glob";
use File::Compare;
use strict;

my @diffs;

############################## dircmp() ##############################
#
# print directory differences
#
# arguments:
#  first directory
#  second directory
#  1 to supress messages about identical files, 0 to show
#
# return:
#  list of differences
#
sub dircmp
{
	my $d1 = shift;
	my $d2 = shift;
	
	compare_dirs($d1, $d2);
	
	return @diffs;
}

sub compare_dirs
{
	# get args
	my $d1 = shift;
	my $d2 = shift;

	# find out what files are in directories
	my %d1_files;
	my %d2_files;
	
	$d1_files{basename($_)} = 0 foreach bsd_glob("$d1/.*");
	$d1_files{basename($_)} = 0 foreach bsd_glob("$d1/*");
		
	delete $d1_files{"."};
	delete $d1_files{".."};

	$d2_files{basename($_)} = 0 foreach bsd_glob("$d2/.*");
	$d2_files{basename($_)} = 0 foreach bsd_glob("$d2/*");
		
	delete $d2_files{"."};
	delete $d2_files{".."};

	# find out what is common and exclusive to each directory
	my %common;
	my @d1_only;
	my @d2_only;
	
	foreach my $x (keys(%d1_files))
	{
		if(defined $d2_files{$x})
		{
			$common{$x} = 0;
		}
		else
		{
			push(@d1_only, $x);
		}
	}

	foreach my $x (keys(%d2_files))
	{
		push(@d2_only, $x) unless defined $common{$x};
	}

	# add missing files to the list
	push(@diffs, "Only in $d1: $_") foreach @d1_only;
	push(@diffs, "Only in $d2: $_") foreach @d2_only;

	# compare common files
	foreach my $x (keys %common)
	{
		my $d1_file = "${d1}/${x}";
		my $d2_file = "${d2}/${x}";

		if((-f $d1_file) && (-f $d2_file))
		{
			unless(compare($d1_file, $d2_file))
			{
				push(@diffs, "Files $d1_file and $d2_file are identical");
			}
			else
			{
				push(@diffs, "Files $d1_file and $d2_file differ");
			}
		}
		elsif((-d $d1_file) && (-d $d2_file))
		{
			compare_dirs($d1_file, $d2_file);
		}
		elsif((-f $d1_file) && (-d $d2_file))
		{
			push(@diffs, "File $d1_file is a regular file while file $d2_file is a directory");
		}
		elsif((-d $d1_file) && (-f $d2_file))
		{
			push(@diffs, "File $d1_file is a directory while file $d2_file is a regular file");
		}
	}
}

1;

=head1 NAME

Dircmp - Use in place of dircmp command

=head1 SYNOPSIS

use File::Dircmp;

dircmp("directory1", "directory2");

The diffs are returned as an array of strings.

=head1 DESCRIPTION

I wrote File::Dircmp so I would not have to use the dircmp command, diff -r --brief on systems without dircmp.

The algorithm I use orders the report differently than the other commands.

=head1 TODO

     -d        Compare the contents of files with the  same  name
               in both directories and output a list telling what
               must be changed in the two  files  to  bring  them
               into  agreement.  The  list format is described in
               diff(1).

     -s        Suppress messages about identical files.

     -w n      Change the width of the output line to  n  charac-
               ters. The default width is  72.

=head1 AUTHOR

Josh Schulte <josh_schulte@yahoo.com>

