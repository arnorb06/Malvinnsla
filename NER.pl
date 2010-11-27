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


sub npcheck {
	my $n = $_[0];
	my $result = "(unknown)";
	if($n =~ /((Sun|Mon|Tues|Wednes|Thurs|Fri|Satur)day)|(January|February|March|April|May|June|July|August|September|October|November|December)/) {
		$result = "TIME";
	}
	elsif($n =~ /[A-Z]?[. ]*(ton|ham|shire|City|Town|Village|Hamlet|Farm|Island)$/){
		$result = "LOCATION";
	}
	elsif($n =~ /[A-Z](.)*(Inc(orporated)?|Corp(oration)?|Army|Company|FC|Club|Marines|Navy|Administration|Office)/) {
		$result = "ORGANIZATION"
	}
	elsif($n =~ /(^[A-Z](.)* ([A-Z](.)*son|O'[A-Z](.)*))|((Sir|Lord|Lady|Miss|Mister|Mr|Ms|Mrs|Reverend|Count|Duke|Baron|Earl|Bishop|Emperor|Empress|King|Queen|President|Prime Minister|Dame|Viscount|Marquis|Professor|Dean|Master|Judge|Cardinal|Deacon|Archduke|Abbot|Father|Friar|Sister|Vicar|Chief|Chieftain|Honourable|Right Honourable|Viceroy|CEO|Pontiff|Sheriff|Magistrate|Minister|Barrister|Judicary|Lord Protector|Regent|Private|Constable|Corporal|Sergeant|Lieutinant|Captain|Major|Colonel|Brigadier|General|Marshall|Admiral|Consul|Senator|Chancellor|Ambassador|Doctor|Governor|Governator|Steward|Seneschal|Principal|Officer|Mistress|Madam|Prince|Princess)( [A-Z][. ]*)?)/) {
		$result = "PERSON";
	}
	return $result;
}

sub cdcheck {
	my $c = $_[0];
	my $linesPosCnt = $_[1];
	my $result = "(unknown)";
	if($c =~ /^[1-2][0-9]{3}/){
		$result = "YEAR";
	}
	elsif(@lines[$linesPosCnt - 1] =~ /^(\$|£|¥|₤|€)/){
		$result = "MONEY";
	}
	elsif(@lines[$linesPosCnt + 1] =~ /[dollar(s)?][pound(s)?][euro(s)?][yen(s)?]/){
		$result = "MONEY";	
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
				$np = $np." $nextword";
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
close($outfile);