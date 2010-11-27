#!usr/bin/perl
# Named Entity Recognizer
# Usage: perl NER.pl <inputfile> <outputfile>
#		 where <inputfile> is a file that has been tagged
#		 according to the Penn Treebank tagset, one word
#		 and its tag per line.
# Authors: Haukur Jónasson & Arnór Barkarson

# Global variable declarations
my $taggedfile = $ARGV[0];
my $outfile = $ARGV[1];
my @out;

my $tokenize_command = "perl ../tokeniser.pl ../ex.in ../ex_token.in";
my $tag_command = "../bin/tree-tagger -token ../english.par ../ex_token.in ../ex.out";

system($tokenize_command);
system($tag_command);

# Reading inputfile
open(FILE,$taggedfile) or die("Cannot open $taggedfile.\n");
my @lines;

foreach(<FILE>) {
	push @lines,$_ unless ($_ =~ / \n/); #Getting rid of empty lines while inserting into array.
}
chomp(@lines);
close($taggedfile);


sub npcheck $np {
	my $type = "(unknown)";
	if($np =~ /(Sun|Mon|Tues|Wednes|Thurs|Fri|Satur)day/) {
		$type = "DAY";
	}
	elsif($np =~ /[A-Z](.)*(ton|ham|shire| City)/){
		$type = "LOCATION";
	}
	elsif($np =~ /[A-Z](.)* ([A-Z](.)*son|O'[A-Z](.)*)/) {
		$type = "PERSON";
	}
	return $type;
}

# Processing input
for(my $i=0;$i<$#lines+1;++$i) {
	chomp(my @line = split(/\t/,$lines[$i]));
	my $word = $line[0];
	my $tag = $line[1];
	my $type = "";
	if($tag =~ /NP(S)?/) {
		push(@out, "[ $line[0]\t$line[1]");
		while(1) {
			my @nextline = split(/ /,$lines[++$i]);
			my $nextword = $nextline[0];
			my $nexttag = $nextline[1];
			chomp($nextword);
			chomp($nexttag);
			#print "$nextword\t$nexttag\n";
			if($nexttag =~ /NP(S)?/) {
				chomp($lines[$i]);
				push(@out, "$lines[$i]");
			}
			else {
				
				push(@out, " | $type ]\n");
				last;
			}
		}
	}
}

# Outputting to file
open(OFILE,">$outfile") or die("Cannot open $outfile.\n");
flock(OFILE, LOCK_EX);
seek(OFILE, 0, SEEK_SET);
 
foreach (@out) {
	print $_;
	print OFILE $_;
}
close($outfile);