#!/usr/bin/perl
use strict;
use Getopt::Long; 
use DB_File;



sub parse_up_header {
	my ($line) = @_;
	$line =~ s/\|/ /g;
	my @parts = split /\s+/, $line;
	my $ref = substr shift(@parts), 1;
	my $acc = shift (@parts);
	$acc =~ s/[\(\)]//g;
	my $desc = join ' ', @parts;
	return ($ref, $acc, $desc);
} # parse_up_header

sub parse_ipi_header {
	my ($line) = @_;
	$line =~ /Tax_Id=\d+/;
	my $refs = $`;
	my $desc = $';
	$refs =~ /IPI:(IPI\d+)/;
	my $ref = $1;
	my $acc;
	if ($refs =~ /SWISS-PROT:(.+?)\|/){
		$acc = $1;
	} # if
	elsif ($refs =~ /TREMBL:(.+?)\|/){
		$acc = $1;
	} # elsif
	else {
		$acc = $ref;
	} # else
	return ($ref, $acc, $desc);
} # parse_ipi_header

sub parse_doe_header {
	my $line = shift;
	$line =~ m/^>(\w+) (\w+) /;
	my ($acc, $ref, $desc) = ($1, $2, $');
	return ($ref, $acc, $desc);
} # end parse_doe_header

sub parse_ebi_header {
	my $line = shift;
	chomp $line;
	$line = substr $line, 1; 
	my @parts = split /\|/, $line;
	my $db = shift @parts;
	my $acc = shift @parts;
	my $remainder = join '|', @parts;
	my @sub_parts = split /\s+/, $remainder;
	my $ref = shift @sub_parts;
	my $desc = join ' ', @sub_parts;
	$desc .= ' DB='.$db;
	return ($ref, $acc, $desc);
} # end parse_ebi_header

sub extract_fasta { # given a in filename, return hashes for ref2acc, ref2desc and ref2seq
	my ($infile, $type) = @_;
	open (INFILE, $infile) or die "Cannot open file $infile for input $@\n";
	my $ref;
	my $acc;
	my $desc;
	my $seq;
	my %ref2acc = ();
	my %ref2desc = ();
	my %ref2seq = ();
	my $count = 0;
	while (my $line = <INFILE>) {
		next if (chomp $line eq '');  # don't get fooled by blank lines
		if ($line =~ /^>/) {
			($ref, $acc, $desc) = parse_up_header($line) if $type eq 'up';
			($ref, $acc, $desc) = parse_ipi_header($line) if $type eq 'ipi';
			($ref, $acc, $desc) = parse_doe_header($line) if $type eq 'doe';
			($ref, $acc, $desc) = parse_ebi_header($line) if $type eq 'ebi';
			$seq = '';
			while (defined ($line = <INFILE>) and not ($line =~/^>/)) {
				$seq .= $line
				} # while
			$ref2acc{$ref} = $acc;
			$ref2desc{$ref} = $desc;
			$ref2seq{$ref} = $seq;
			redo;
			} # if
		} # while
	close INFILE;
	return (\%ref2acc, \%ref2desc, \%ref2seq);
	} # extract_fasta


sub index_db_core {
	my ($file, $type, $path) = @_;
	my (%r2a, %r2d, %r2s);
	$file =~ /\.fasta$/i;
	my $name = $`;
	$name = $path.'/'.$name if (defined $path);
	my ($ref2acc, $ref2desc, $res2seq) = extract_fasta($file, $type);
	tie %r2a, "DB_File", "$name.r2a" or die "Cannot tie hash r2a to $name.r2a\n";
	tie %r2d, "DB_File", "$name.r2d" or die "Cannot tie hash r2d to $name.r2d\n";
	tie %r2s, "DB_File", "$name.r2s" or die "Cannot tie hash r2s to $name.r2s\n";
	%r2a = %$ref2acc;
	%r2d = %$ref2desc;
	%r2s = %$res2seq;
	untie %r2a;
	untie %r2d;
	untie %r2s;
	return;
} # index_db_core


sub usage {  
	print <<"USAGE";
Program:  index_db.pl
	This program takes fasta formated protein files and creates indexed files for MCW Proteomics Suite 
	Written by Brian D. Halligan, Ph.D. October 2008  Version 2.00
	Options are:
		--input			=> name of fasta file to be processed [required]
		--output		=> path to output database 
		--type			=> protein header type (up [default] ebi ipi doe)
		--help			=> display usage
USAGE
		exit;
} # usage

#######################  MAIN   #######################

	my $time = localtime;
	my $input;
	my $output;
	my $type = 'up';
	my $help;
	my $results = GetOptions (	"input=s"		=> \$input,
								"output=s"		=> \$output,
								"type=s"		=> \$type,
								"help"			=> \$help); 
	usage () if (defined $help);
	usage () if (not defined $input);
	index_db_core($input, $type, $output);
