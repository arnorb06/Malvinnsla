#!usr/bin/perl
# Named Entity Recognizer
# Authors: Arnór Barkarson & Haukur Jónasson

# Global variable declarations
my $infile = $ARGV[0];				# Plaintext input file
my $tokfile = '../tokenised.txt';	# Intermediate output: Tokenised text file
my $taggedfile = '../tagged.txt';	# Intermediate output: Tagged text file
my @lines;							# Array for reading input
my $outfile = $ARGV[1];				# Final output file
my @out;							# Array containing terminal output
my $locfile = 'loc.txt';			# Textfile containing list of locations
my @locations;						# Array for location list
my $flags = $ARGV[2];				# Optional flag string
my $f_output = 0;					# If 1: Output to terminal
my $f_help = 0;						# If 1: Don't scan, instead print help
my $f_num_only = 0;					# If 1: Only scan cardinal numbers
my $f_pnoun_only = 0;				# If 1: Only scan proper nouns
my $numOfUnknown = 0;				# Number of unidentified words/numbers
my $numOfTags = 0;					# Total number of words/numbers

# Process input, set flags
sub input {
	if($flags =~ /\-[onph]+/) {
		if($flags =~ /o/) {
			$f_output = 1;
		}
		if($flags =~ /h/) {
			$f_help = 1;
		}
		if($flags =~ /n/) {
			$f_num_only = 1;
		}
		if($flags =~ /p/) {
			$f_pnoun_only = 1;
		}
	}
}

# Process files necessary for execution, run tokeniser and tagger
sub preprocess {	
	my $tokenise_command = "perl ../tokeniser.pl $infile $tokfile";
	my $tag_command = "../bin/tree-tagger -token ../english.par $tokfile $taggedfile";

	system($tokenise_command);	# Run tokeniser
	system($tag_command);		# Run PoS tagger
	
	# Reading inputfile
	open(FILE,$taggedfile) or die("Cannot open $taggedfile\n");

	foreach(<FILE>) {
		push @lines,$_ unless ($_ =~ / \n/);		#Getting rid of empty lines while inserting into array.
	}
	chomp(@lines);
	close($taggedfile);

	# Reading locfile
	open(LOCFILE,$locfile) or die("Cannot open $locfile\n");
	foreach(<LOCFILE>) {
		push @locations,$_;
	}
	close($locfile);

	# Preparing outputfile
	open(OFILE,">$outfile") or die("Cannot open $outfile\n");
	flock(OFILE, LOCK_EX);
	seek(OFILE, 0, SEEK_SET);
}

# This subroutine uses regular expressions to try to guess what $pnoun is,
# without looking at the context, only the word itself.
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
	my $pnoun = $_[0];		# The word being identified
	my $index = $_[1];		# Array location
	my $result = "(unknown)";
	
	chomp(my @prevline = split(/\s+/,$lines[$index-2]));
	chomp(my @nextline = split(/\s+/,$lines[$index]));
	my $prevword = $prevline[0]; 		# The previous word
	my $nextword = $nextline[0];		# The next word
	if(( $prevword =~ /^[Ss](aid|ays)$/ ) or ($nextword =~ /^[Ss](aid|ays)$/)) {		# Checking for preceding or trailing said/says
		$result = "PERSON";								# Identified as person	
		$numOfUnknown--;
	}
	elsif($prevword =~ /^[Ii]n$/) {														# Checking for preceding location-adverb
		$result = "LOCATION";							# Identified as location
		$numOfUnknown--;
	}
	elsif($prevword =~ /^(([Tt]he)|a(n)?)$/) {											# Checking for preceding determinant
		$result = "THING";								# Identified as non-person
		$numOfUnknown--;
	}
	if( $result eq "(unknown)") {
		while($index<$#lines+1) {		
			chomp(my @line = split(/\s+/,$lines[$index]));
			if($line[0] =~ /^([Hh]e|[Ss]he|[Hh](is|er))$/){								# Looking for nearby he/she/his/her
				$result = "PERSON";						# Identified as person
				$numOfUnknown--;
				last;
			}
			elsif($line[0] =~ /^([Ii]t(s)?|)$/) {										# Looking for nearby it/its
				$result = "THING";						# Identified as non-person
				$numOfUnknown--;
				last;
			}
			elsif($line[1] =~ /NP(S)?/) {												# Looking for next NP/NPS
				last;									# Aborting
			}
			$index+=1;
		}
	}
	return $result;
}

# Using regular expressions, identify which type $c is
sub cdcheck {
	my $c = $_[0];
	my $linesPosCnt = $_[1];
	my $result = "QUANTITY";
	my @l;
	chomp(@l = split(/\t/,$lines[$linesPosCnt - 1]));
	if($c =~ /(.*ion)/){
		$result = "QUANTITY";
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

# Print help to terminal
sub help {
	print "	* ABOUT :\n";
	print "	This program will scan through an English plaintext document and\n";
	print "	tag each word by part-of-speach. This is done with TreeTagger by\n";
	print "	Helmut Schmid of the University of Stuttgart. The main function \n";
	print "	is to mark all cardinal numbers (CD) and proper nouns (NP/NPS)  \n";
	print "	specifically with brackets and try to identify their type. The  \n";
	print "	types this program identifies are:\n\n";
	print "    		 Cardinal numbers:\n";
	print "        		TIME\n";
	print "				MONEY\n";
	print "        		PERCENTAGE\n";
	print "        		QUANTITY\n";
	print "    		Proper nouns:\n";
	print "        		PERSON\n";
	print "        		LOCATION\n";
	print "        		TIME (name of a month or day of week)\n";
	print "        		THING (non-person)\n\n";
	print "	* USAGE :\n";
	print "	To use this program, run the following command on your terminal:\n";
	print "			perl NER.pl <inputfile> <outputfile> [-flags]\n";
	print "	where the optional 'flags' is replaced by any of the following flags:\n\n";
	print "				o : Print output to terminal\n";
	print "				h : Print this help\n";
	print "\n";
	print "	* CREDITS :\n";
	print "	Perl script written by:\n";
	print "				Arnor Barkarson\n";
	print "				Haukur Jonasson\n";
	print "	for the BSc course Natural Language Processing (Malvinnsla) at the \n";
	print "	Department of Computer Science at the University of Reykjavik,\n";
	print "	November 2010.\n\n";
}

# Print output and results to terminal
sub output {
	if($f_output) {
			foreach (@out) {
				print $_;
			}
		}

		print "NUMBER OF TAGS : $numOfTags\n";
		print "NUMBER OF UNKNOWN : $numOfUnknown\n";
		my $hitrate = ($numOfTags - $numOfUnknown)/$numOfTags;
		my $hitperc = $hitrate * 100;
		printf("TAGGED : %.2f \%\n",$hitperc);
}

sub main {
	input();
	
	if( $f_help ) {
		help();
	}
	else {
		preprocess();
		for(my $i=0;$i<$#lines+1;++$i) {			# For each line in the tagged file
			chomp(my @line = split(/\t/,$lines[$i]));		# Seperate the tag from the word
			my $word = $line[0];
			my $tag = $line[1];
			my $type = "";
			my $np = $word;									# Concatenation of marked words 
			if( not $f_num_only) {
				if($tag =~ /NP(S)?/) {							# Word is tagged as NP/NPS
					$numOfTags++;
					print OFILE "[ $line[0]";
					push(@out, "[ $line[0]");
					while(1) {
						my @nextline = split(/\t/,$lines[++$i]);
						my $nextword = $nextline[0];
						my $nexttag = $nextline[1];
						chomp($nextword);
						chomp($nexttag);
						if($nexttag =~ /NP(S)?/) {				# The next word is an NP/NPS too..
							$numOfTags++;
							$np = $np." $nextword";				# Concatenate!
							chomp($lines[$i]);
							print OFILE " $nextline[0] ";
							push(@out, " $nextline[0]");
						}
						else {
							$type = npcheck($np);					# Simple regex check...
							if($type eq "(unknown)") {				# Returned nothing?
								$type = npcontext($np, $i);			# More complex contextual check
							}
							print OFILE " NP | $type ] ";
							push(@out, " NP | $type ]\n");
							if($nexttag eq 'CD' and not $f_pnoun_only){		# Next word is a number
								$numOfTags++;
								$type = cdcheck($nextword, $i);
								print OFILE "[ $nextword\t$nexttag | $type ] ";
								push(@out, "[ $nextword\t$nexttag | $type ]\n");
							}
							else{
								print OFILE " $nextword $nexttag";
							}
							if($nexttag eq 'SENT'){					# End of sentence found
								print OFILE "\n";
							}
							last;
						}
					}
				}
			}
			if( not $f_pnoun_only) {
				if($tag =~ /CD/){		# Word is tagged as CD (number)
					$numOfTags++;
					$type = cdcheck($np, $i);
					print OFILE "[ $line[0]\t$line[1] | $type ] ";
					push(@out, "[ $line[0]\t$line[1] | $type ]\n");
				}
			}
			elsif($tag eq 'SENT'){		# End of sentence found
				print OFILE "$word $tag\n";	
			}
			else{
				print OFILE " $word $tag ";
			}
		}
		output();
		close($outfile);
	}
}

main();