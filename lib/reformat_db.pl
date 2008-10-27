#!/usr/bin/perl
use strict;

sub reformat_db {
	my $infname = shift @_;
	my $outfname = shift @_;
	open FILEIN, $infname or return ("Could not open file $infname for input $!");
	open FILEOUT, ">$outfname" or return ("Could not open file $outfname for output $!");
	while (my $line = <FILEIN>) {
		if ($line =~ /^>/) {
			my ($db, $acc, $remainder) = split /\|/, $line;
			$remainder =~ /\s+/;
			my $ref = $`;
			my $desc = $';
			print FILEOUT "$db|$ref|($acc) $desc";
		} # if
		else {
			print FILEOUT $line;
		} # else
	} # while
	close FILEIN;
	close FILEOUT;
	return ("Success - reformatted db");
} # reformat_db

sub usage {  
	print <<"USAGE";
Program:  reformat_db.pl
	This program takes a fasta database file downloaded from UniProt and reformats header line 
	Written by Brian D. Halligan, Ph.D. October 2008  Version 1.00

	usage:
	reformat_db.pl infile outfile

USAGE
		exit;
} # usage

	usage () if (scalar @ARGV < 2);
	my $result = reformat_db($ARGV[0], $ARGV[1]);
	print "$result\n";
	exit;

	