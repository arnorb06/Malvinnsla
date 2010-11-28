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
my $numOfUnKnown = 0;
my $numOfNPs = 0;
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


sub npcheck {
	my $n = $_[0];
	my $result = "(unknown)";
	if($n =~ /((Sun|Mon|Tues|Wednes|Thurs|Fri|Satur)day)|(January|February|March|April|May|June|July|August|September|October|November|December)/) {
		$result = "TIME";
	}
	elsif($n =~ /[A-Z]?[. ]*(ton|ham|shire|City|Town|Village|Hamlet|Farm|Island|Ocean|Lake|River|[Ww]ood|House)/){

		$result = "LOCATION";
	}
	elsif($n =~ /(^[A-Z](.)* ([A-Z](.)*son|O'[A-Z](.)*))|((Sir|Lord|Lady|Miss|Mister|Mr|Ms|Mrs|Reverend|Count|Duke|Baron|Earl|Bishop|Emperor|Empress|King|Queen|President|Prime Minister|Dame|Viscount|Marquis|Professor|Dean|Master|Judge|Cardinal|Deacon|Archduke|Abbot|Father|Friar|Sister|Vicar|Chief|Chieftain|Honourable|Right Honourable|Viceroy|CEO|Pontiff|Sheriff|Magistrate|Minister|Barrister|Judicary|Lord Protector|Regent|Private|Constable|Corporal|Sergeant|Lieutinant|Captain|Major|Colonel|Brigadier|General|Marshall|Admiral|Consul|Senator|Chancellor|Ambassador|Doctor|Governor|Governator|Steward|Seneschal|Principal|Officer|Mistress|Madam|Prince|Princess)( [A-Z][. ]*)?)/) {
		$result = "PERSON";
	}
	if($result eq "(unknown)"){
		$numOfUnKnown++;
	}
	return $result;
}

sub cdcheck {
	my $c = $_[0];
	my $linesPosCnt = $_[1];
	my $result = "(unknown)";
	my @l;
	chomp(@l = split(/\t/,$lines[$linesPosCnt - 1]));
	if($c =~ /(.*ion)/){
		$result = "MONEY";
	}
	elsif($c =~ /^[1-2][0-9]{3}/){
		$result = "TIME";
	}
	elsif( $l[0] =~ /^(\$|£|¥|₤|€)/){
		$result = "MONEY";
	}
	chomp(@l = split(/\t/,$lines[$linesPosCnt + 1]));
	if($c =~ /^([0-9]|[0-1][0-9]|2[0-3])[:][0-5][0-9]$/){
		$result = "TIME";	
	}
	elsif($l[0] =~ /^(dollar(s)?)|(pound(s)?)|(euro(s)?)|(yen)|(.*ion)|[A-Z]{3}/){
		$result = "MONEY";	
	}
	if($result eq "(unknown)"){
		$numOfUnKnown++;
	}
	return $result;
}

# Processing input
for(my $i=0;$i<$#lines+1;++$i) {
	chomp(my @line = split(/\t/,$lines[$i]));
	my $word = $line[0];
	my $tag = $line[1];
	my $type = "";
	my $np = $word;
	if($tag =~ /NP(S)?/) {
		$numOfNPs++;
		push(@out, "[ $line[0]");
		while(1) {
			my @nextline = split(/\t/,$lines[++$i]);
			my $nextword = $nextline[0];
			my $nexttag = $nextline[1];
			chomp($nextword);
			chomp($nexttag);
			#print $nexttag;
			#print "$nextword\n";
			if($nexttag =~ /NP(S)?/) {
				$numOfNPs++;
				$np = $np." $nextword";
				#print "----> This is np : ".$np;
				chomp($lines[$i]);
				push(@out, " $nextline[0]");
				#push(@out, "$lines[$i]");
			}
			else {
				$type = npcheck($np);
				push(@out, " NP | $type ]\n");
				last;
			}
		}
	}
	if($tag =~ /CD/){
		$type = cdcheck($np, $i);
		push(@out, "[ $line[0]\t$line[1] | $type]\n");
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

print "NUMBER OF NP's : $numOfNPs\n";
print "NUMERR OF UNKNOWN : $numOfUnKnown\n";
my $hitrate = ($numOfNPs - $numOfUnKnown)/$numOfNPs;
print "HITRATE = $hitrate\n";
close($outfile);