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
use DB_File;
use File::Basename;
use File::DosGlob 'glob';
use URI::Escape;
	
our $version = "1.00 LINUX";

	our @mod_codes = ('*', '#', '@', '^', '~', '$');  # standard sequest modification codes
	our %mod_hash;
	our $scans;
	our $fasta;
	our $params;
	our $dtas;

sub parse_tandem_xml {
	my ($input_data) = @_;
	my $xml  = XMLin($input_data,
		ForceArray => 1,
		KeyAttr    => {},
	  );
	return if (not exists $xml->{group});
	my @groups = @{$xml->{group}};
	for my $j (0..$#groups) {
		my %content = %{$groups[$j]};
		if ($content{type} eq 'model') {
			my @sub_groups = @{$content{group}};
			my $scan =  $sub_groups[1]->{note}->[0]->{content};
			$scan =~ s/\s//g;
			$scans->{$scan}->[1]->{mass}=  $sub_groups[1]->{'GAML:trace'}->[0]->{'GAML:attribute'}->[0]->{content};
			$scans->{$scan}->[1]->{charge}=  $sub_groups[1]->{'GAML:trace'}->[0]->{'GAML:attribute'}->[1]->{content};
			my @proteins = @{$content{protein}};
			$scans->{$scan}->[1]->{source} = 'TANDEM';
			$scans->{$scan}->[1]->{raw_name} = $scan;
			$scans->{$scan}->[1]->{name} = $scan;
			$scans->{$scan}->[1]->{rank} = 1;
			$scans->{$scan}->[1]->{number} = 1;
			$scans->{$scan}->[1]->{match_mass} = $proteins[0]->{peptide}->[0]->{domain}->[0]->{mh};
			my $start = $proteins[0]->{peptide}->[0]->{domain}->[0]->{start};
			my $core = $proteins[0]->{peptide}->[0]->{domain}->[0]->{seq};
			$scans->{$scan}->[1]->{core} =  $core;
			$scans->{$scan}->[1]->{length} =  length $core;
			if (exists $proteins[0]->{peptide}->[0]->{domain}->[0]->{aa}) {
				my @parts = split //, $core;
				my @aas = @{$proteins[0]->{peptide}->[0]->{domain}->[0]->{aa}};
				foreach my $aa (@aas) {
					my $at = $aa->{at};
					my $loc = $at - $start;
					my $type = $aa->{type};
					my $modified = $aa->{modified};
					if (not exists $mod_hash{$type}{$modified}){
						$mod_hash{$type}{$modified} =  shift @mod_codes;
					} # if
					$parts[$loc] .= $mod_hash{$type}{$modified};
				} # foreach
				$core = join //, @parts;
			} # if
			my $pre = $proteins[0]->{peptide}->[0]->{domain}->[0]->{pre};
			my $post = $proteins[0]->{peptide}->[0]->{domain}->[0]->{post};
			my $pre_aa = substr $pre, -1, 1;
			if ($pre_aa =~ /[R|K|-]/) {
				$scans->{$scan}->[1]->{nTryp} = 1;
			} # if
			else {
				$scans->{$scan}->[1]->{nTryp} = 0;
			} # else
			my $last = substr $scans->{$scan}->[1]->{core}, -1;
			if ($last =~ /[R|K|-]/) {
				$scans->{$scan}->[1]->{cTryp} = 1;
			} # if
			else {
				$scans->{$scan}->[1]->{cTryp} = 0;
			} # else
			$scans->{$scan}->[1]->{ntt} = $scans->{$scan}->[1]->{cTryp} + $scans->{$scan}->[1]->{nTryp};
			my $post_aa = substr $post, 0, 1;
			$scans->{$scan}->[1]->{match_peptide} = "$pre_aa.$core.$post_aa";
			foreach my $key (keys %{$proteins[0]->{peptide}->[0]->{domain}->[0]}){
				$scans->{$scan}->[1]->{$key} = $proteins[0]->{peptide}->[0]->{domain}->[0]->{$key};
			} # foreach key
			$scans->{$scan}->[1]->{peptide_prob} = 1-$scans->{$scan}->[1]->{expect};
			my %ref_hash;
			foreach my $i (0..$#proteins){
				my ($db, $acces, $text, $ref, $desc);
				my $protein_label = $proteins[$i]->{label};
				if ($protein_label =~ /^IPI\|(IPI[\d\.]+)\|/){
					$acces = $1;
					$ref = $1;
					$desc = $';
				} # if
				elsif ($protein_label =~ /\((\w+)\)/) {
					$ref = $`;
					$acces = $1;
					$desc = $';
				} # elsif
				elsif ($protein_label =~ /\|/) {
					($db, $acces, $text) = split /\|/, $protein_label;
					my @parts = split /\s+/, $text;
					$ref = shift @parts;
					$desc = join ' ', @parts;
				} # elsif
				else {
					$protein_label =~ /$(\w+)\s/;
					$ref = $1;
					$acces = $1;
					$desc = $';
				} # else
				$ref_hash{$ref} = 1;;
				$fasta->{$ref}->{sequence} = $proteins[$i]->{peptide}->[0]->{content};
				$fasta->{$ref}->{description} = $desc;
				$fasta->{$ref}->{accession} = $acces;
			} # for i
			my @refs = keys %ref_hash;
			$scans->{$scan}->[1]->{pep_repeats} = scalar @refs;
			if (scalar @refs > 1) {
				$scans->{$scan}->[1]->{reference} = shift @refs;
				$scans->{$scan}->[1]->{add_ref} = [@refs];
			} # if
			else {
				$scans->{$scan}->[1]->{reference} = shift @refs;
			} # else
			my $dta = "$scans->{$scan}->[1]->{match_mass} $scans->{$scan}->[1]->{charge}\n";
			my $x_num_values = $sub_groups[1]->{'GAML:trace'}->[0]->{'GAML:Xdata'}->[0]->{'GAML:values'}->[0]->{'numvalues'};
			my $y_num_values = $sub_groups[1]->{'GAML:trace'}->[0]->{'GAML:Ydata'}->[0]->{'GAML:values'}->[0]->{'numvalues'};
			my @masses = split /\s+/, $sub_groups[1]->{'GAML:trace'}->[0]->{'GAML:Xdata'}->[0]->{'GAML:values'}->[0]->{content};
			my @intens = split /\s+/, $sub_groups[1]->{'GAML:trace'}->[0]->{'GAML:Ydata'}->[0]->{'GAML:values'}->[0]->{content};
			print "Error Scan $scan Number of values not equal X $x_num_values Y $y_num_values ", scalar @masses, " ",  scalar @intens, "\n" if ($x_num_values != $y_num_values);
			for my $i (0..$x_num_values) {
				my $mass = sprintf "%.2f", $masses[$i];
				my $inten = sprintf "%.1f", $intens[$i];
				$dta .= "$mass $inten\n";
			} # for i
			$dtas->{$scan} = $dta;
		} # if
		elsif ($content{type} eq 'parameters') {
			my $type = $content{label};
			my @param_list = @{$content{note}};
			foreach my $param (@param_list){ 
				if ($param !~ /HASH/){
					print "Param is not hash :$param:\n";
					next;
				} # if
				my $param_label = $param->{label};
				my $content = '';
				$content = $param->{content} if (exists  $param->{content});
				if ($param_label =~ /(.+), (.+)/){
					$params->{$type}->{$1}->{$2}= $content;
				} # if
				else {
					$params->{$type}->{$param_label}->{$param_label} = $content;
				} # else
			} # foreach param 
		} # elsif
	} # for j
	return;
}# sub parse_tandem_xml

	
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
			$protein_summary{$reference}{description} = $fasta->{$reference}->{description};
			$protein_summary{$reference}{accession} = $fasta->{$reference}->{accession};
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
	

sub write_ez2 {  # produces a stand alone zip file	
	my ($proteins, $scans, $fasta, $min_ppscore, $params, $dtas, $outfile, $source) = @_;
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
	if ($dtas =~ /HASH/) {  # check to see if dtas are included in this format
		foreach my $dta_name (keys %{$dtas}){
			$zip->addString( $dtas->{$dta_name}, $dta_name );
		} # foreach dta_name
	} # if
	my $xml = XMLout($params, keeproot => 1, keyattr => []);
	$zip->addString( $xml, 'param.xml' );
	$zip->addFile('/pipeline/vipdac/config/tool_versions.yml') if (-e '/pipeline/vipdac/config/tool_versions.yml');
	my $ezf_name =$outfile.'.ez2';
	$ezf_name .= '.ez2' if ($ezf_name !~ /\.ez2$/);
	return (-1) unless $zip->writeToFileNamed($ezf_name) == AZ_OK;
	return (1);
} # write_ez2

sub make_scan_xml {  
	my ($scans) = @_;
	my $scan_xml = XML::Smart->new();
	my %scan = %{$scans};
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
	my $params_xml = XML::Smart->new(ForceArray => 1);
	foreach my $key (keys %{$params}) {	
		$params_xml->{'tandem'}->{$key} = \%{$params->{$key}};
	} # foreach key
	my $count = 0;
	foreach my $aa (keys %mod_hash) {
		foreach my $mass (keys %{$mod_hash{$aa}}) {
			my $symbol = $mod_hash{$aa}{$mass};
			$params_xml->{modifications}->[$count]->{aa} = $aa;
			$params_xml->{modifications}->[$count]->{symbol} = $symbol;
			$params_xml->{modifications}->[$count]->{mass} = $mass;
			$count++;
		} # foreach mass
	} # foreach aa 
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

sub usage {  
	print <<"USAGE";
Program:  tandem_aws2ez2.pl
	This program takes zip files or directories containing 'Amazon cloud produced' x!Tandem xml files and creates a single .ez2 file.
	  NB.  All .xml files are assumed to derive fron a single .raw file. 
	Written by Brian D. Halligan, Ph.D. January 2009  Version 1.00 LINUX
	Options are:
		--input			=> name of zip file to be processed [required]
		--output		=> name of output .ez2 file [default is input.ez2]
		--species		=> UniProt species tag of actual species [default is HUMAN]

USAGE
		exit;
} # usage

#######################  MAIN   #######################

	my $time = localtime;
	my $species = 'HUMAN';
	my ($input, $output);
	my $verbose = 0;
	my $help = 0;
	my $results = GetOptions (	"help"			=> \$help,
								"input=s"		=> \$input,
								"output=s"		=> \$output,
								"species=s"		=> \$species,
								"verbose"		=> \$verbose); 
	usage () if (not defined $input);
	$output = substr $input, 0, -4 . '.ez2' if ($output !~ /\w/);
	if ( $input =~ /\.zip$/) {
		my $tandem_zip = Archive::Zip->new();
		unless ( $tandem_zip->read( $input ) == AZ_OK ) {
			die "Cannot read file $input for input\n";
		} # unless
		if ( my @files = $tandem_zip->membersMatching( '.*\.xml'  )) {
			print scalar @files, " .xml files found in $input\n";
			foreach my $file (@files) {
				print "Reading file $file\n";
				my $tandem_data = $tandem_zip->contents($file);
				parse_tandem_xml($tandem_data);
			} # foreach
		} # if
		else {
			print "Did not find .xml files in $input\n";
			exit;
		} # else
	} # if
	elsif ( $input =~ /\.xml$/) {
		open XML, $input or die "Could not open file $input $!\n";
		my $tandem_data = join '', <XML>;
		close XML;
		parse_tandem_xml($tandem_data);
	} # elsif
	elsif ( -d $input) {
		print "$input is a directory\n";
		my @files = glob "$input/*.xml";
		foreach my $file (@files) {
			print "Reading file $file\n";
			parse_tandem_xml($file);
		} # foreach file
	} # elsif
	else {
		print "Bad file type for file $input\n";
		exit;
	} # else
	my $scans_found = scalar keys %{$scans};
	print "$scans_found scans were found\n";
	my $proteins = scans2protein_summary($scans, $species, 0);
	my $proteins_found = scalar keys %{$proteins};
	print "$proteins_found proteins were found\n";
	my ($header_yaml,$scan_yaml);
	my $threshold = 0.6;
	write_ez2($proteins, $scans, $fasta, $threshold, $params, $dtas, $output, 'X!TANDEM');
	print "Wrote file $output\n";
	print "Time => $time\n";
