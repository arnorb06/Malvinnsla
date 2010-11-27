#!usr/bin/perl
# Named Entity Recognizer
# Usage: perl NER.pl <inputfile> <outputfile>
#		 where <inputfile> is a file that has been tagged
#		 according to the Penn Treebank tagset, one word
#		 and its tag per line.
# Authors: Haukur J�nasson & Arn�r Barkarson

# Global variable declarations
my $taggedfile = $ARGV[0];
my $outfile = $ARGV[1];
my @out;


# Reading inputfile
open(FILE,$taggedfile) or die("Cannot open $taggedfile.\n");
my @lines;

foreach(<FILE>) {
	push @lines,$_ unless ($_ =~ / \n/); #Getting rid of empty lines while inserting into array.
}
chomp(@lines);
print "$#lines\n";
close($taggedfile);

# Processing input
for(my $i=0;$i<$#lines+1;++$i) {
	chomp(my @line = split(/ /,$lines[$i]));
	my $word = $line[0];
	my $tag = $line[1];
	#$tag =~ s/\n//;			#Remove newlines from tags
	#chomp($tag);
	#chomp($word);
	if($tag eq "NP") {
		print "$word\t$tag\n";
		push(@out, "[ $line[0]\t$line[1]");
		while(1) {
			my @nextline = split(/ /,$lines[++$i]);
			my $nextword = $nextline[0];
			my $nexttag = $nextline[1];
			chomp($nextword);
			chomp($nexttag);
			#print "$nextword\t$nexttag\n";
			if($nexttag eq "NP") {
				chomp($lines[$i]);
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
 
foreach (@out) {
	print $_;
	print OFILE $_;
}
close($outfile);