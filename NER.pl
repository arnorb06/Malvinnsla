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

# Reading inputfile
open(FILE,$taggedfile) or die("Cannot open $taggedfile.\n");
my @lines;

foreach(<FILE>) {
	push @lines,$_ unless ($_ =~ /^ \n/); #Getting rid of empty lines while inserting into array.
}
print "$#lines\n";
close($taggedfile);

# Processing input
for(my $i=0;$i<$#lines+1;++$i) {
	my @line = split(/ /,$lines[$i]);
	my $word = $line[0];
	my $tag = $line[1];
	$tag =~ s/\n//;			#Remove newlines from tags
	if($tag eq 'NNP') {
		push(@out, "[ $line[0]\t$line[1]");
		while(1) {
			my $nextword,$nexttag = split(/ /,$lines[++$i]);
			if($nexttag eq 'NNP') {
				push(@out, "$lines[$i]");
			}
			else {
				push(@out, " ]\n");
				last;
			}
		}
	}
}

# Outputting to file
open(OFILE,">$outfile") or die("Cannot open $outfile.\n");
flock(OFILE, LOCK_EX);
seek(OFILE, 0, SEEK_SET);
 
foreach $x (@out) {
	print OFILE $x;
}
close($outfile);