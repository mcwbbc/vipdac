#!/usr/bin/perl

use strict;
use Getopt::Long; 
use XML::Smart;
use XML::Simple;
use XML::SAX::Expat;
	$XML::Simple::PREFERRED_PARSER = "XML::SAX::Expat";
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Data::Dumper;
use YAML;
use Text::CSV;
use DB_File;

	
our $version = "1.01 UNIX";

sub read_xml { # generic subroutine for reading xml into hash
	my ($xml) = @_;
	my %content = %{XMLin($xml)};
	my %output = ();
	foreach my $key (keys %content) {
		my $new_key = $content{$key}{'name'};
		foreach my $sub_key (keys %{$content{$key}}){
			next if $sub_key eq 'name';
			$output{$new_key}{$sub_key} = $content{$key}{$sub_key};
		} # foreach sub_key
	}# foreach key
	return \%output;
} # read_xml


sub parse_omssa_csv {
	my ($scans, $mods, $omssa_data, $species) = @_;
    my $csv = Text::CSV->new();
	my @lines = split /\n/, $omssa_data;
	shift @lines;
	my %scan_hash;
	foreach my $line (@lines) {
		if (not $csv->parse($line)) {
			 print "Could not parse line $line\n";
			 next;
		} # if
		my ($spec_numb, $scan, $peptide, $evalue, $mass, $gi, $reference, $start, $stop, $description, $modifications, $charge, $match_mass, $pvalue, $nist_score) = $csv->fields();
		my @search = ();
		$scan =~s/^\W+//;
		$reference = ($reference =~ /\-/) ? $` : $reference;
		if (not exists $scan_hash{$scan}) {
			$search[0]{charge} = $charge;
			$search[0]{mass} = $mass;
			$search[0]{tic} = 0;
			$search[0]{name} = $scan;
			$search[1]{name} = $scan;
			$scan =~ /\./;
			$search[0]{raw_name} = $`;
			$search[1]{raw_name} = $`;
			$search[1]{charge} = $charge;
			$search[1]{mass} = $mass;
			$search[1]{tic} = 0;
			$search[1]{core} = uc $peptide;
			$search[1]{match_peptide} = '-.'.$peptide.'.-';
			$search[1]{core} = uc $peptide;
			$search[1]{length} = length $peptide;
			$search[1]{match_mass} = $match_mass;
			$search[1]{deltaMass} = abs($match_mass-$mass);
			$search[1]{gi_ref} = $gi;
			$search[1]{reference} = $reference;
			if ($description =~ /^\((.+?)\) /){
				$search[1]{accession} = $1;
				$search[1]{description} = $';
			} # if
			elsif ($description =~ /^IPI\|(IPI[\d\.]+)\|/){
				$search[1]{accession} = $1;
				$search[1]{reference} = $1;
				$search[1]{description} = $';
			} # if
			else {
				$search[1]{description} = $description;
			} # else
			if ($modifications =~ /\w/) {
				$search[1]{modifications} = $modifications;
				if ($modifications =~ /\,/) {
					$csv->parse($modifications);
					my @submods = $csv->fields();
					foreach my $smod (@submods) {
						if ($smod =~ /(.+)\:/){
							$mods->{$1} = [] if (not exists $mods->{$1});
							push @{$mods->{$1}}, $scan;
						} # if
					} # foreach smod		
				} # if
				else {
					if ($modifications =~ /(.+):/){
						$mods->{$1} = [] if (not exists $mods->{$1});
						push @{$mods->{$1}}, $scan;
					} # if
				} # else
			} # if
			$search[1]{omssa_evalue} = $evalue;
			$search[1]{omssa_pvalue} = $pvalue;
			$search[1]{nist_score} = $nist_score;
			$search[1]{peptide_prob} = 1 - $pvalue;
			$search[1]{pep_start} = $start;
			$search[1]{pep_stop} = $stop;
			$search[1]{rank} = 1;
			$search[1]{number} = 1;
			$scans->{$scan} = \@search;
		} # if
		else {
			$search[1]{add_ref} = [] if (not defined $search[1]{add_ref});
			if ($reference =~ /\_$species/) {
				push @{$search[1]{add_ref}}, $search[1]{reference};
				$search[1]{reference} = $reference;
				$search[1]{description} = $description;
				if ($description =~ /^\((.+?)\) /){
					$search[1]{accession} = $1;
					$search[1]{description} = $';
				} # if
			} # if
			else {
				push @{$search[1]{add_ref}}, $reference;
			} # else
		} # else
	}  # foreach line
	return;
} # parse_omssa_csv
	
sub scans2protein_summary {  # given a ref to scans, extract the protein structure
	my ($scans, $target_species, $verbose) = @_;
	my %proteins=();
	for my $key (keys %{$scans}){
		my $reference = $scans->{$key}->[1]->{reference};
		if (exists $scans->{$key}->[1]->{add_ref}){			
			my ($gene, $species) = split /_/, $reference;
			my $var = $scans->{$key}->[1]->{add_ref};
			if ($var !~ /ARRAY/) { # if this is not an array, force it to be one
				$scans->{$key}->[1]->{add_ref} = [$scans->{$key}->[1]->{add_ref}];
			} # if
			my @addrefs = @{$scans->{$key}->[1]->{add_ref}};
			my ($gene, $species) = split /_/, $reference;
			if ($species ne $target_species) {
				for my $i  (0..$#addrefs) { 
					my ($add_gene, $add_species) = split /_/, $addrefs[$i];
					next if $add_species ne $target_species;
					my $temp = $reference;
					$reference = $addrefs[$i];
					$addrefs[$i] = $temp;
					last;
				} # for i
			} # if
			foreach my $addref (@addrefs) {  # add to the duplicate references
				next if (($addref =~ /$gene/) or not ($addref =~ /$species/));
				if (not defined $proteins{$addref}) {
					$proteins{$addref} = [];
				} # ir
				push @{$proteins{$addref}}, $scans->{$key}->[1];
			} # foreach addref
		} # if exists addrefs
		$proteins{$reference} = [] if not defined $proteins{$reference};
		push @{$proteins{$reference}}, $scans->{$key}->[1];
	} # for keys
	my %protein_summary;
	my %multi_hit_spectra = ();
	my %peptide_prob = (); # keep track of max pp score for each peptide form (NB charge state and modifications  are considered as seperate forms)
	foreach my $reference (keys %proteins) {
		$protein_summary{$reference}{description} = '';  # switch to post anotation
		$protein_summary{$reference}{accession} = '';
		$protein_summary{$reference}{scans} = [];
		$protein_summary{$reference}{peptides} = [];
		$protein_summary{$reference}{scan_count} = 0;
		$protein_summary{$reference}{peptide_count} = 0;
		$protein_summary{$reference}{total_tic} = 0;
		$protein_summary{$reference}{total_xcorr} = 0;
		$protein_summary{$reference}{max_xcorr} = 0;
		$protein_summary{$reference}{protein_prob} = 0;
		$protein_summary{$reference}{pep2scan} = ();
		my %peptide_hash = ();
		foreach my $search (@{$proteins{$reference}}){
			$protein_summary{$reference}{description} = $search->{description};
			$protein_summary{$reference}{accession} = $search->{accession};
			push @{$protein_summary{$reference}{scans}}, $search->{name};
			push @{$protein_summary{$reference}{peptides}}, $search->{match_peptide};
			$protein_summary{$reference}{pep2scan}{$search->{core}} = [] if (not exists $protein_summary{$reference}{pep2scan}{$search->{core}});  
			push @{$protein_summary{$reference}{pep2scan}{$search->{core}}}, $search->{name};
			$protein_summary{$reference}{scan_count}++;
			$protein_summary{$reference}{peptide_count}++ if not exists $peptide_hash{$search->{core}};
			$peptide_hash{$search->{core}} = 1;
			$protein_summary{$reference}{total_tic} += $search->{tic};
			$protein_summary{$reference}{total_xcorr} += $search->{xcorr};
			$protein_summary{$reference}{max_xcorr} =  $search->{xcorr} if $protein_summary{$reference}{max_xcorr} <  $search->{xcorr};
			my $peptide_form = $search->{charge}.$search->{match_peptide};  # add charge to front end to make each charge state a new form
			if (not exists $peptide_prob{$reference}{$peptide_form}) {
					$peptide_prob{$reference}{$peptide_form} = $search->{peptide_prob};
				} # if
				else {
					if ( $search->{peptide_prob} > $peptide_prob{$reference}{$peptide_form}) {
						$peptide_prob{$reference}{$peptide_form} = $search->{peptide_prob};
					} # if
				} # else
		} # foreach search
		$protein_summary{$reference}{score} = $protein_summary{$reference}{max_xcorr}*$protein_summary{$reference}{peptide_count}*($protein_summary{$reference}{scan_count}/10);
		if ($reference =~ /^RND-/) {
		} # if
	} # foreach reference# first pass, calculate protein probs without the degenerate peptides
	foreach my $reference (keys %proteins) {
		my $product = 1;
		foreach my $peptide_form (keys %{$peptide_prob{$reference}}) {
			$product *= (1-$peptide_prob{$reference}{$peptide_form});
		} # foreach peptide_form
		$protein_summary{$reference}{protein_prob} = 1-$product;
	} # foreach reference
	return \%protein_summary;
} # scans2protein_summary
	
sub db2fasta {
	our (%r2a, %r2d, %r2s);
	my $protein_summary = shift @_;
	my $db = shift @_;
	return -1 if (tie_hash($db) == -1);
	my %fasta;
	foreach my $protein (keys %{$protein_summary}) {
		if (exists  $r2a{$protein}) {
			$fasta{$protein}{accession} = $r2a{$protein};
			$protein_summary->{$protein}->{accession} = $r2a{$protein};
			$fasta{$protein}{description} = $r2d{$protein};
			$protein_summary->{$protein}->{description} = $r2d{$protein};
			$fasta{$protein}{sequence} = $r2s{$protein};
		} # if
		else {
			if ($protein =~ /\./){
				$protein = $`;
				redo;
			}# if
		} # else
	} # foreach
	return (1, \%fasta);
} # db2fasta
	
sub dta_string {
	my %data = %{shift @_};
	my $charge = $data{charge};
	my $pepmass = $data{pepmass};
	my $mass = $pepmass*$charge - $charge +1;
	my $dta = "$mass $charge\n";
	foreach my $point (@{$data{spectra}}){
		my ($mass, $inten) = @{$point};
		$mass = sprintf "%.2f", $mass;
		$inten = sprintf "%.1f", $inten;
		$dta .= "$mass $inten\n";
	} # foreach point
	return $dta
} # dta_string

	
sub parse_mgf {
	my $fname = shift @_;
	my $scans = shift @_;
	if (not open IN, $fname) {
		warn "Could not open $fname for input $!\n";
		return -1;
	} # if
	my %data;
	my %dtas;
	while (my $line = <IN>) {
		next if $line !~ /\w/;
		if ($line  =~ /BEGIN IONS/) {
			my ($title, $charge, $pepmass, @spectra, $start, $end);
			my $min = 10000000;
			my $max = 0;
			my $base = 0;
			my $sum = 0;
			my $count = 0;
			while (my $line = <IN>) {
				chomp $line;
				next if $line !~ /\w/;
				if ($line  =~ /TITLE=(.*)$/) {
					$title = $1;
					$title =~ s/\s+$//;
					next if (not exists $scans->{$title});
					my @parts = split /\./, $title;
					$start = $parts[1];
					$end = $parts[2];
				}# if
				elsif ($line  =~ /CHARGE=(\d)\+/) {
					$charge = $1;
				}# elsif
				elsif ($line  =~ /PEPMASS=(.*)$/) {
					$pepmass = $1;
				}# elsif
				elsif ($line  =~ /^\d/) {
					my ($mass, $inten) = split /\s/, $line;
					push @spectra, [$mass, $inten];
					$count++;
					$sum += $inten;
					if ($inten > $max) {
						$max = $inten;
						$base = $mass;
					} # if
					$min = $inten if ($min > $inten);
				} # elsif
				elsif ($line  =~ /END IONS/) {
					$data{start} = $start;
					$data{end} = $end;
					$data{title} = $title;
					$data{pepmass} = $pepmass;
					$data{charge} = $charge;
					$data{min} = $min;
					$data{max} = $max;
					$data{base} = $base;
					$data{sum} = $sum;
					$data{count} = $count;
					$data{spectra} = \@spectra;
					$dtas{$title} = dta_string(\%data);
					last;
				} #elsif
				else {
					warn "Unknown line $line\n";
				} # else
			} # while
		} # if
	} # while
	return \%dtas;
} # parse_mgf


sub make_param_hash_omssa {
	our $version;
	my $data = shift;
	my $input = shift;
	my $output = shift;
	my $threshold = shift;
	my $species = shift;
	my $omssa_params = shift;
	my %params;
	$params{analysis}{program} = $0;
	$params{analysis}{version} = $version;
	$params{analysis}{time} = localtime;
	$params{analysis}{input_file} = $input;
	$params{analysis}{output_file} = $output;
	$params{analysis}{threshold} = $threshold;
	$params{analysis}{species} = $species;
	my @parts = split /\s+/, $omssa_params;
	for (my $i = 0; $i < $#parts; $i+=2) {
		$params{OMSSA}{$parts[$i]} = $parts[$i+1];
	} # for i
	return \%params;
} # make_param_hash_omssa

sub write_ez2 {  # produces a stand alone zip file	
	my ($proteins, $scans, $fasta, $min_ppscore, $params, $dtas, $outfile, $source, $header_yaml, $scan_yaml) = @_;
	my $time_now = localtime;
	my $protxml = make_protein_xml($proteins);
	my $scanxml = make_scan_xml($scans);
	my $paramxml = make_params_xml($params);
	my $fastaxml = make_fasta_xml($fasta);
	my $zip = Archive::Zip->new();
	$zip->addString( $protxml, 'protein_summary.xml' );
	$zip->addString( $scanxml, 'scans.xml' );
	$zip->addString( $paramxml, 'param.xml' );
	$zip->addString( $fastaxml, 'fasta.xml' );
	$zip->addString( $header_yaml, 'rawheader.yaml' );
	$zip->addString( $scan_yaml, 'scan2rt.yaml' );
	if ($dtas =~ /HASH/) {  # check to see if dtas are included in this format
		if ($source =~ /MASCOT/){
			foreach my $dta_name (keys %{$dtas}){
				my $dta_string = make_dta_string($dtas->{$dta_name});
				$zip->addString( $dta_string, "$dta_name" );
			} # foreach dta_name
		} # if
		elsif ($source =~ /OMSSA/){
			foreach my $dta_name (keys %{$dtas}){
				$zip->addString( $dtas->{$dta_name}, $dta_name );
			} # foreach dta_name
		} # elsif
	} # if
	my $xml = XMLout($params, keeproot => 1, keyattr => []);
	$zip->addString( $xml, 'param.xml' );
	my $ezf_name =$outfile;
	$ezf_name .= '.ez2' if ($ezf_name !~ /\.ez2$/);
	return (-1) unless $zip->writeToFileNamed($ezf_name) == AZ_OK;
	return (1);
} # write_ez2

sub make_scan_xml {  
	my ($scans) = @_;
	my $scan_xml = XML::Smart->new();
	my %scan = %{$scans};
	warn "in make_scan_xml I found ", scalar keys %{$scan{proteins}}, " proteins\n" if (exists $scan{proteins});
	my $count = 1;
	foreach my $scan_key (keys %scan) {
		next if ($scan_key eq 'proteins');
		$scan_xml->{'scans'}{"scan_$count"}{'name'} = $scan_key;
		foreach my $key (keys %{$scan{$scan_key}[1]}) {
			$scan_xml->{'scans'}{"scan_$count"}{$key} = $scan{$scan_key}[1]{$key};
		} # foreach key
		$count++;
	} # foreach scan_key
	my $data = $scan_xml->data();
	return $data;
} # make_scan_xml

sub make_params_xml {
	my ($params) = @_;
	my $params_xml = XML::Smart->new();
	$params_xml->{'parameters'} = $params;
	my $data = $params_xml->data();
	return $data;
} # make_params_xml

sub make_fasta_xml {
	my ($fasta) = @_;
	my $fasta_xml = XML::Smart->new();
	my $count = 1;
	foreach my $name (sort keys %$fasta){
		$fasta_xml->{'sequence'}{"sequence_$count"}{'name'} = $name;
		foreach my $key (keys %{$fasta->{$name}}){
			$fasta_xml->{'sequence'}{"sequence_$count"}{$key} = $fasta->{$name}->{$key};
		} # foreach key
	$count++;
	} # foreach name
	my $data = $fasta_xml->data();
	return $data;
} # make_fasta_xml


sub make_protein_xml {  
	my ($proteins) = @_;
	my $protein_xml = XML::Smart->new();
	my %protein = %{$proteins};
	my $count = 1;
	foreach my $protein_key (keys %protein) {
		$protein_xml->{'proteins'}{"protein_$count"}{'name'} = $protein_key;
		foreach my $key (keys %{$protein{$protein_key}}) {
			if ($key eq 'pep2scan') {
				my $pcount= 1;
				foreach my $p2s (keys %{$protein{$protein_key}{$key}}) {
					my $scount = 1;
					$protein_xml->{'proteins'}{"protein_$count"}{$key}{"peptide_$pcount"}{'sequence'} = $p2s;
					foreach my $scan (@{$protein{$protein_key}{$key}{$p2s}}){
						next if $scan eq 'placeholder';
						$protein_xml->{'proteins'}{"protein_$count"}{$key}{"peptide_$pcount"}{"scan_$scount"} = $scan;
						$scount++;
					} # foreach
				$pcount++;
				} # foreach
			} # if
			else {
				$protein_xml->{'proteins'}{"protein_$count"}{$key} = $protein{$protein_key}{$key};
			} # else
		} # foreach key
		$count++;
	} # foreach protein_key
	my $data = $protein_xml->data();
	return $data;
} # make_protein_xml

sub tie_hash {  #ties the hash to databases
	our $main_prop;
	our ($actual_db, $database_dir, %r2a, %r2d, %r2s, $index_db_types, %default);
	my $db = shift @_;
	$db =~ s/\.(r2a|r2d|r2s)$//;
	my $working_db;
	$working_db = $db;
check_db:
	goto missing_db if (not -e "$working_db.r2a"); 
	goto missing_db if (not -e "$working_db.r2d"); 
	goto missing_db if (not -e "$working_db.r2s"); 
	goto missing_db if ( not tie  %r2a, "DB_File", "$working_db.r2a"); 
	goto missing_db if ( not tie  %r2d, "DB_File", "$working_db.r2d"); 
	goto missing_db if ( not tie  %r2s, "DB_File", "$working_db.r2s"); 
#	print "r2a entries ",  scalar keys %r2a, "\n";
#	print "r2d entries ",  scalar keys %r2d, "\n";
#	print "r2s entries ",  scalar keys %r2s, "\n";
	goto missing_db if ( scalar keys %r2a < 2); 
	goto missing_db if ( scalar keys %r2d < 2); 
	goto missing_db if ( scalar keys %r2s < 2); 
	return 1; 
missing_db: 
	die "Cannot find database :$working_db:\n";	
} # tie_hash

sub untie_hash {
	our (%r2a, %r2d, %r2s);
	untie %r2a;
	untie %r2d;
	untie %r2s;
	return;
} # untie_hash

sub fix_match_peptide {
	my ($scans, $fasta) = @_;
	foreach my $scan (keys %{$scans}) {
		my $core = $scans->{$scan}->[1]->{core};
		my $reference = $scans->{$scan}->[1]->{reference};
		my $sequence = $fasta->{$reference}->{sequence};
		next if ($scans->{$scan}->[1]->{description} =~ /REVERSED/);
		$sequence =~ s/\W//g;
		$sequence = '-'.$sequence.'-';
		if ($sequence =~ /(.)$core(.)/) {
			$scans->{$scan}->[1]->{match_peptide} =$1.'.'.$core.'.'.$2;
			$scans->{$scan}->[1]->{nTryp} = 1 if ($core =~/[KR]$/);
			$scans->{$scan}->[1]->{cTryp} = 1 if ($scans->{$scan}->[1]->{match_peptide} =~/^[KR\-]\./);
			$scans->{$scan}->[1]->{ntt} = $scans->{$scan}->[1]->{nTryp} + $scans->{$scan}->[1]->{cTryp};
		} # if
	} # foreach
} # fix_match_peptide



sub read_mods_xml {
	my $mods_fname = shift;
	my %content = %{XMLin($mods_fname)};
	my @mod_array = @{$content{MSModSpec}};
	my %mods;
	foreach my $i (0..$#mod_array) {
		my $item = $mod_array[$i];
		$mods{$i}{mass} = $item->{MSModSpec_monomass};
		$mods{$i}{name} = $item->{MSModSpec_name};
		if ($item->{MSModSpec_residues}->{MSModSpec_residues_E} =~ /ARRAY/) {
			$mods{$i}{residues} =$item->{MSModSpec_residues}->{MSModSpec_residues_E};
		} # if
		elsif (exists $item->{MSModSpec_residues}->{MSModSpec_residues_E}) {
			$mods{$i}{residues} =[$item->{MSModSpec_residues}->{MSModSpec_residues_E}];
		} # elif
		else {
			$mods{$i}{residues} = [];
		} # else
		push @{$mods{$i}{residues}}, 'n-term' if ($mods{$i}{name} =~ /n-term/);
		push @{$mods{$i}{residues}}, 'n-term' if ($mods{$i}{name} =~ /nterm/);
		push @{$mods{$i}{residues}}, 'c-term' if ($mods{$i}{name} =~ /c-term/);
		push @{$mods{$i}{residues}}, 'c-term' if ($mods{$i}{name} =~ /cterm/);
	} # foreach item
	return \%mods;
} # read_mods_xml


sub usage {  
	print <<"USAGE";
Program:  omssa_aws2ez2.pl
	This program takes zip files containing 'Amazon cloud produced' OMSSA csv files and creates a single .ez2 file.
	  NB.  All .csv files are assumed to derive fron a single .raw file. 
	Written by Brian D. Halligan, Ph.D. September 2008  Version 1.00
	Options are:
		--input			=> name of zip file to be processed [required]
		--output		=> name of output .ez2 file [default is input.ez2]
		--raw			=> name of raw file [required]
		--dta			=> name of diectory of .dta files [either dta or mgf is required to add scan data]
		--mgf			=> name of mgf file [either dta or mgf is required to add scan data]
		--db			=> name of database file [required]
		--mods			=> name of mods.xml file [default is mods.xml]
		--species		=> UniProt species tag of actual species [default is HUMAN]
		--threshold		=> min probability value for each spectrum [default is 0]

USAGE
		exit;
} # usage

#######################  MAIN   #######################

	my $time = localtime;
	my $species = 'HUMAN';
	my $mods_fname = 'mods.xml';
	my ($input, $output, $dta_fname, $mgf_fname, $raw_fname, $db_fname);
	my $threshold = 0;
	my $verbose = 0;
	my $help = 0;
	my $results = GetOptions (	"threshold=i"	=> \$threshold, 
								"help"			=> \$help,
								"input=s"		=> \$input,
								"output=s"		=> \$output,
								"mgf=s"			=> \$mgf_fname,
								"dta=s"			=> \$dta_fname,
								"raw=s"			=> \$raw_fname,
								"db=s"			=> \$db_fname,
								"mods=s"		=> \$mods_fname,
								"species=s"		=> \$species,
								"verbose"		=> \$verbose); 
	usage () if (not defined $db_fname);
	usage () if ((not defined $input) and (not defined $output));
	$output = substr $input, 0, -4 . '.ez2' if ($output !~ /\w/);
	my $param_data;
	my $scans = {};
	my $modifications = {};
	if ( $input =~ /\.zip$/) {
		my $omassa_zip = Archive::Zip->new();
		unless ( $omassa_zip->read( $input ) == AZ_OK ) {
			die "Cannot read file $input for input\n";
		} # unless
		if ( my @files = $omassa_zip->membersMatching( '.*\.csv'  )) {
			print scalar @files, " .csv files found in $input\n";
			foreach my $file (@files) {
				my $omssa_data = $omassa_zip->contents($file);
				parse_omssa_csv($scans, $modifications, $omssa_data, $species);
			} # foreach
		} # if
		else {
			print "Did not find .csv files in $input\n";
			exit;
		} # else
		if ( my ($param_file) = $omassa_zip->membersMatching( 'parameters.conf'  )) {
			print "The OMSSA parameter file parameters.conf found in $input\n";
			$param_data = $omassa_zip->contents($param_file);
		} # if
		else {
			print "Did not find parameters.conf in $input\n";
		} # else
	} # if
	elsif ( $input =~ /\.csv$/) {
		open CSV, $input or die "Could not open file $input $!\n";
		my $omssa_data = join '', <CSV>;
		close CSV;
		parse_omssa_csv($scans, $modifications, $omssa_data);
	} # elsif
	else {	
		my $target_dir = (defined $input) ? $input : '.';  
		opendir DIR, $target_dir;
		my @files = grep {$_ =~ /\.csv$/i} readdir DIR;
		close DIR;
		die "No .csv files found in directory $target_dir\n" if (scalar @files < 1);
		print scalar @files, " .csv files found in directory $target_dir\n";
		foreach my $file (@files) {
			my $input_file = $target_dir.'/'.$file;
			open FILEIN, $input_file or die "Cannot open file $input_file $!\n";
			my @lines = <FILEIN>;
			close FILEIN;
			my $omssa_data = join '', @lines;
			parse_omssa_csv($scans, $modifications, $omssa_data);
		} # foreach
	} # else
	my %mods = read_mods_xml($mods_fname);
	my $spect_found = scalar keys %{$scans};
	print "$spect_found spectra were found\n";
	my $proteins = scans2protein_summary($scans);
	my $proteins_found = scalar keys %{$proteins};
	print "$proteins_found proteins were found\n";
	my ($fasta_result, $fasta) = db2fasta($proteins, $db_fname);
	fix_match_peptide($scans, $fasta);
	my ($dta_result, $dtas);
	if (defined $dta_fname){
		($dta_result, $dtas) = dta2dta($scans,$dta_fname);
	} # if
	elsif (defined $mgf_fname){
		$dtas = parse_mgf($mgf_fname, $scans);
	} # if
	else {
		warn "Could not add scan data\n";
	} # else
	my $params = make_param_hash_omssa($scans, $input, $output, $threshold, $species, $param_data);
	my ($header_yaml,$scan_yaml);   # this data is not available on non-Windows systems
	write_ez2($proteins, $scans, $fasta, $threshold, $params, $dtas, $output, 'OMSSA', $header_yaml,$scan_yaml);
	print "Wrote file $output\n";
	print "Time => $time\n";
