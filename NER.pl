#!usr/bin/perl
# Named Entity Recognizer
# Authors: Haukur Jónasson & Arnór Barkarson
use 5.010;

my $taggedfile = $ARGV[0];
my $outfile = $ARGV[1];
my $out = '';
my @outputlines;

open(FILE,$taggedfile) or die("Cannot open $taggedfile.\n");
#flock(FILE, LOCK_EX);
#seek(FILE, 0, SEEK_SET); 
my @lines;
push(@lines,$line);

foreach(<FILE>) {
	push @lines,$_ unless ($_ =~ /^ \n/); #Getting rid of empty lines.
}
say "$#lines";
close($taggedfile);

for(my $i=0;$i<$#lines+1;++$i) {
	my @line = split(/ /,$lines[$i]);
	my $word = $line[0];
	my $tag = $line[1];
	$tag =~ s/\n//;			#Remove newlines
	if($tag eq 'NNP') {
		push(@outputlines, "[ $line[0]\t$line[1]");
		#say $out;
		while(1) {
			my $nextword,$nexttag = split(/ /,$lines[++$i]);
			if($nexttag eq 'NNP') {
				push(@outputlines, "$lines[$i]");
			}
			else {
				push(@outputlines, " ]\n");
				last;
			}
		}
	}
	else {
		#say $tag;
	}
}
#say $out;
open(OFILE,">$outfile") or die("Cannot open $outfile.\n");
flock(OFILE, LOCK_EX);
seek(OFILE, 0, SEEK_SET);
#say $out; 
foreach $x (@outputlines) {
	print OFILE $x;
}
close($outfile);