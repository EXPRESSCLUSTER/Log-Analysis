#!/usr/bin/perl -w

#
# Usage:
#
#	./merge.pl [Time delta] [Log directory] [Head part of log filename]
#
#	[Head part of log filename]	The string matches to the head part of the file name under the "HOSTNAME/log" directory.
#
#	[Log directory] must have the following structure.
#
#	./
#	├───node-1
#	│   ├───log
#	│   :   ├───userlog.00.log
#	|   :   :
#	|
#	└───node-2
#	    ├───log
#	    :   ├───userlog.00.log
#	    :   :
#
# Sample:
#
#	# node-1 log is 10 sec behind node-1 log.
#	# Current directory contains the directories for all the nodes in the cluster
#	# Analysing userlog* 
#	./merge.pl -10 . userlog
#

use strict;
use warnings;
use Cwd;
use Time::Local 'timelocal';
use Time::HiRes 'tv_interval';
my ($msec, $sec, $min, $hour, $mday, $month, $year, $wday, $stime) = (0,0,0,0,0,0,0,0,0);
my @dirs = ();
my %lines = ();

if ($#ARGV < 2) {
	print("Usaage : $0 [Time delta] [Log directories root] [Filename]\n");
	exit 1;
}

my $cwd = Cwd::getcwd();
opendir(IN, $cwd."/".$ARGV[1]) or die ("[E] opendir($ARGV[1]):($!)");
my @files = readdir(IN) or die ("[E] readdir:($!)");
closedir(IN);
chdir $ARGV[1];

# Node2 - Node1 = timedelta:
my $timedelta = $ARGV[0];
my $timeadjust = 0;
my $tab="\t";
foreach my $dir (sort @files){
	if((-d $dir) && ($dir ne ".") && ($dir ne "..")){
		opendir(IN, "$dir/log") or next;
		my @files2 = readdir(IN) or next;
		push @dirs, $dir;
		foreach my $file (sort @files2) {
			if($file =~ /^$ARGV[2]/){
				open(IN2, "$dir/log/$file") or next;
				print("[D] reading [$dir/log/$file]\n");
				while(<IN2>){
					chop;
					my $msg = "";
					if (/^(....)\/(..)\/(..) (..):(..):(..).(...) (.*)$/) {
						($year,$month,$mday,$hour,$min,$sec,$msec,$msg) = ($1,$2,$3,$4,$5,$6,$7,$8);
					}
					$month	-= 1;
					my $epoch = timelocal($sec, $min, $hour, $mday, $month, $year);
					$epoch -= $timeadjust;

					# Retrieving Log level
					my $lvl = "";
					if ($msg =~ s/(INFO |WARN |ERROR|START|\*END\*)//) {
						$lvl = $1;
					}

					# Deleting PID TID form userlog.NN.log.
					$msg =~ s/ [0-9a-f]{8} [0-9a-f]{8} //;

					# Deleting PID TID form rcN.log etc.
					$msg =~ s/\[P:.{8}\]\[T:.{8}\]\s*//;

					# Filtering : Skipping lines containing useless message.
					next if ($msg =~ /Cluster Disk Resource Performance Data can't be collected because a performance monitor is too numerous./);

					my $line = sprintf("$epoch $msec $dir\t$lvl$tab$msg\n");
					push @{$lines{$dir}}, $line;
				}
				close(IN2);
			}
		}
		$tab .= "\t";
		$timeadjust += $timedelta;
		closedir(IN);
	}
}

my ($sec1, $msec1) = (0, 0);	# time for node1
my ($sec2, $msec2) = (0, 0);	# time for node2
my $seccurr = 0;
my $secprev = 0;
while(1){
	my $line = "";
	if ( ( scalar(@{$lines{$dirs[0]}} ) == 0) &&
	     ( scalar(@{$lines{$dirs[1]}} ) == 0) ) {
		last;
	}
	elsif ( scalar(@{$lines{$dirs[0]}}) == 0 ) {
		$line = shift @{$lines{$dirs[1]}};
	}
	elsif ( scalar(@{$lines{$dirs[1]}}) == 0 ) {
		$line = shift @{$lines{$dirs[0]}};
	} else {
		if ( $lines{$dirs[0]}[0] =~ /^(.*?) (.*?) / ) {
			($sec1, $msec1) = ($1, $2);
		}
		if ( $lines{$dirs[1]}[0] =~ /^(.*?) (.*?) / ) {
			($sec2, $msec2) = ($1, $2);
		}
		my $secdiff = tv_interval([$sec1, $msec1*1000],[$sec2, $msec2*1000]);
		if ( $secdiff > 0 ) {
			$line = shift @{$lines{$dirs[0]}};
		} else {
			$line = shift @{$lines{$dirs[1]}};
		}
	}

	next if ($line !~ /^(\d+?) (\d+?) (.*)/);
	my ($seccurr, $mseccurr, $msg) = ($1, $2, $3);

	if ($secprev == 0){
		$secprev = $seccurr - ($seccurr % 60) + 60;
	}

	while ($seccurr > $secprev){
		my ($sec, $min, $hour, $mday, $month, $year, $wday, $yday, $isdst) = localtime($secprev);
		if ($seccurr - $secprev > 60*60*24){
			eval{
				$secprev = timelocal(0, 0, 0, $mday+1, $month, $year);
			};
			if($@){
				$secprev += 60*60*24;
			}
		} elsif($seccurr - $secprev > 60*60){
			eval{
				$secprev = timelocal(0, 0, $hour+1, $mday, $month, $year);
			};
			if($@){
				$secprev += 60*60;
			}
		} elsif($seccurr - $secprev > 60){
			eval{
				$secprev = timelocal(0, $min+1, $hour, $mday, $month, $year);
			};
			if($@){
				$secprev += 60;
			}
		} else {
			last;
		}
		($sec, $min, $hour, $mday, $month, $year, $wday, $yday, $isdst) = localtime($secprev);
		printf("%d/%02d/%02d %02d:%02d:%02d.000\n", $year+1900, $month+1, $mday, $hour, $min, $sec);
	}
	$secprev = $seccurr;
	($sec, $min, $hour, $mday, $month, $year, $wday, $stime) = localtime($seccurr);
	printf("%d/%02d/%02d %02d:%02d:%02d.%03d $msg\n", $year+1900, $month+1, $mday, $hour, $min, $sec, $mseccurr);
}
