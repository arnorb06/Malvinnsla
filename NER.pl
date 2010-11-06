#!usr/bin/perl
# Named Entity Recognizer
# Authors: Haukur Jónasson & Arnór Barkarson
use 5.010;

my $taggedfile = $ARGV[0];
my $out = '';

open(FILE,$taggedfile) or die("Cannot open $taggedfile.\n");
#flock(FILE, LOCK_EX);
#seek(FILE, 0, SEEK_SET); 
my @lines;
#while($line = <FILE>) {
#	next if /^$/;
#	push(@lines,$line);
#}

foreach(<FILE>) {
	push @lines,$_ unless ($_ =~ /^ \n/);
}
say "$#lines";
close($taggedfile);

for(my $i=0;$i<$#lines+1;++$i) {
	my @line = split(/ /,$lines[$i]);
	my $word = $line[0];
	my $tag = $line[1];
	say $tag;
	if($tag == 'NNP') {
		$out = join( $out, "[ $line ");
		while(1) {
			my $nextword,$nexttag = split(/ /,$lines[++$i]);
			if($nexttag == 'NNP') {
				$out = join($out, $lines[$i]);
			}
			else {
				$out = join($out, ' ]\n');
				last;
			}
		}
	}
}

say $out;