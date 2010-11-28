#!usr/bin/perl
# Named Entity Recognizer
# Usage: perl NER.pl <inputfile> <outputfile>
#		 where <inputfile> is a file that has been tagged
#		 according to the Penn Treebank tagset, one word
#		 and its tag per line.
# Authors: Haukur Jónasson & Arnór Barkarson

# Global variable declarations
my $infile = $ARGV[0];
my $tokfile = '../tokenised.txt';
my $taggedfile = '../tagged.txt';
my $outfile = $ARGV[1];
my $logfile = 'log.txt';
my $locfile = 'loc.txt';
my @out;
my $numOfUnknown = 0;
my $numOfTags = 0;
my $tokenise_command = "perl ../tokeniser.pl $infile $tokfile";
my $tag_command = "../bin/tree-tagger -token ../english.par $tokfile $taggedfile";

system($tokenise_command);
system($tag_command);

# Preparing logfile for output
open(LOGFILE,">$logfile") or die("Cannot open $logfile\n");
flock(LOGFILE, LOCK_EX);
seek(LOGFILE, 0, SEEK_SET);

# Reading locfile
open(LOCFILE,$locfile) or die("Cannot open $locfile\n");
my @locations;
foreach(<LOCFILE>) {
	push @locations,$_;
}
close($locfile);

# Reading inputfile
open(FILE,$taggedfile) or die("Cannot open $taggedfile\n");
my @lines;
foreach(<FILE>) {
	push @lines,$_ unless ($_ =~ / \n/); #Getting rid of empty lines while inserting into array.
}
chomp(@lines);
close($taggedfile);

# This subroutine uses regular expressions to try to guess what $pnoun is, without looking at the context.
sub npcheck {
	my $pnoun = $_[0];
	my $result = "(unknown)";
	foreach(@locations) {
		chomp($_);
		chomp($pnoun);
		if($_ eq $pnoun) {
			$result = "LOCATION";
			last;
		}
	}
	if($result eq "(unknown)") {
		if($pnoun =~ /((Sun|Mon|Tues|Wednes|Thurs|Fri|Satur)day)|(January|February|March|April|May|June|July|August|September|October|November|December)/) {
			$result = "TIME";
		}
		elsif($pnoun =~ /[A-Z]?[. ]*(ton|ham|shire|[Ww]ood|City|[Tt]own|Village|Hamlet|Farm|Island|Ocean|Lake|River|House|Hotel|Sea(s)?|Mountain(s)?|[Rr]idge(s)?|County)/){
			$result = "LOCATION";
		}
		elsif($pnoun =~ /[A-Z]?(.)*(Inc(orporated)?|Corp(oration)?|Army|Company|Party|FC|Club|Marines|Navy|Administration|Office|Centre|Center|Society|Department|School|University|Academy|College)/) {
			$result = "ORGANIZATION"
		}
		elsif($pnoun =~ /(^([A-Z](.)* )?([A-Z](.)*son|O'[A-Z](.)+|Mc[A-Z](.)+)( |$))|((Sir|Lord|Lady|Miss|Mister|Mr|Ms|Mrs|Reverend|Count|Duke|Baron|Earl|Bishop|Emperor|Empress|King|Queen|President|Prime Minister|Dame|Viscount|Marquis|Professor|Dean|Master|Judge|Cardinal|Deacon|Archduke|Abbot|Father|Friar|Sister|Vicar|Chief|Chieftain|Honourable|Right Honourable|Viceroy|CEO|Pontiff|Sheriff|Magistrate|Minister|Barrister|Judicary|Lord Protector|Regent|Private|Constable|Corporal|Sergeant|Lieutinant|Captain|Major|Colonel|Brigadier|General|Marshall|Admiral|Consul|Senator|Chancellor|Ambassador|Doctor|Governor|Governator|Steward|Seneschal|Principal|Officer|Mistress|Madam|Prince|Princess)( [A-Z][. ]*)?)/) {
			$result = "PERSON";
		}
	}
	if($result eq "(unknown)"){
		$numOfUnknown++;
	}
	return $result;
}

# Using the context, this subroutine tries to guess what $pnoun is
sub npcontext {
	my $pnoun = $_[0];
	my $index = $_[1];
	my $result = "(unknown)";
	print LOGFILE "*** Trying to identify < $pnoun > ***\n";
	chomp(my @prevline = split(/\s+/,$lines[$index-2]));
	chomp(my @nextline = split(/\s+/,$lines[$index]));
	my $prevword = $prevline[0];
	my $nextword = $nextline[0];
	if(( $prevword =~ /^[Ss](aid|ays)$/ ) or ($nextword =~ /^[Ss](aid|ays)$/)) {
		$numOfUnknown--;
		$result = "PERSON";	
	}
	elsif($prevword =~ /^[Ii]n$/) {
		$numOfUnknown--;
		$result = "LOCATION";
	}
	elsif($prevword =~ /^[Tt]he$/) {
		$numOfUnknown--;
		$result = "THING";
	}
	if( $result eq "(unknown)") {
		while($index<$#lines+1) {		
			chomp(my @line = split(/\s+/,$lines[$index]));
			if($line[0] =~ /^([Hh]e|[Ss]he|[Hh](is|er))$/){
				$result = "PERSON";
				$numOfUnknown--;
				print LOGFILE "********** < $pnoun > is a PERSON because < $line[0] > refers to it. *****\n\n";
				last;
			}
			elsif($line[0] =~ /^([Ii]t(s)?|)$/) {
				$result = "THING";
				print LOGFILE "********** < $pnoun > is a THING because < $line[0] > refers to it.\n\n";
				$numOfUnknown--;
				last;
			}
			elsif($line[1] =~ /NP(S)?/) {
				print LOGFILE "********** New proper noun < $line[0] > found, aborting < $pnoun >\n\n";
				last;
			}
			else {
				print LOGFILE "****** < $line[0] > does not refer to < $pnoun > \n";
			}
			$index+=1;
		}
	}
	return $result;
}

sub cdcheck {
	my $c = $_[0];
	my $linesPosCnt = $_[1];
	my $result = "NUMBER";
	my @l;
	chomp(@l = split(/\t/,$lines[$linesPosCnt - 1]));
	if($c =~ /(.*ion)/){
		$result = "NUMBER";
	}
	elsif($c =~ /^[1-2][0-9]{3}/){
		$result = "TIME";
	}
	elsif( $l[0] =~ /^(\$|£|¥|₤|€)/){
		$result = "MONEY";
	}
	chomp(@l = split(/\t/,$lines[$linesPosCnt + 1]));
	if($c =~ /%$/ or $l[0] eq '%' or $l[0] =~ /[Pp]ercent/){
		$result = "PERCENTAGE";	
	}
	elsif($c =~ /^([0-9]|[0-1][0-9]|2[0-3])[:][0-5][0-9]$/){
		$result = "TIME";	
	}
	elsif($l[0] =~ /^(dollar(s)?)|(pound(s)?)|(euro(s)?)|(yen)|(.*ion)|[A-Z]{3}/){
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
		$numOfTags++;
		push(@out, "[ $line[0]");
		while(1) {
			my @nextline = split(/\t/,$lines[++$i]);
			my $nextword = $nextline[0];
			my $nexttag = $nextline[1];
			chomp($nextword);
			chomp($nexttag);
			if($nexttag =~ /NP(S)?/) {
				$numOfTags++;
				$np = $np." $nextword";
				#print "----> This is np : ".$np;
				chomp($lines[$i]);
				push(@out, " $nextline[0]");
			}
			else {
				$type = npcheck($np); 			# Simple regex check...
				if($type eq "(unknown)") { 		# Returned nothing?
					$type = npcontext($np, $i);	# More complex contextual check
				}
				push(@out, " NP | $type ]\n");
				last;
			}
		}
	}
	if($tag =~ /CD/){
		$numOfTags++;
		$type = cdcheck($np, $i);
		push(@out, "[ $line[0]\t$line[1] | $type]\n");
	}
}

# Outputting to file
open(OFILE,">$outfile") or die("Cannot open $outfile\n");
flock(OFILE, LOCK_EX);
seek(OFILE, 0, SEEK_SET);
 
foreach (@out) {
	print $_;
	print OFILE $_;
}

print "NUMBER OF TAGS : $numOfTags\n";
print "NUMBER OF UNKNOWN : $numOfUnknown\n";
my $hitrate = ($numOfTags - $numOfUnknown)/$numOfTags;
print "HITRATE = $hitrate\n";
close($outfile);
close($logfile);