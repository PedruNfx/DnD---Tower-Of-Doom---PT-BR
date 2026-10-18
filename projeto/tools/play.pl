# Auto-play: coin+start+pick a character, then walk right attacking; screenshots every N seconds.
# usage: play.pl seconds shot_every [nostart]
use strict; use warnings; use Time::HiRes qw(time); use FindBin; require "$FindBin::Bin/pad.pl";
my ($secs, $every, $nostart) = @ARGV; $every ||= 3;
unless ($nostart) {
  Pad::hold(0.3, 'SELECT'); Pad::idle(1.0); Pad::hold(0.2, 'START'); Pad::idle(2.5);   # coin, start
  Pad::hold(0.2, 'B'); Pad::idle(2.0);                                                 # pick fighter
}
my $t0 = time; my $last = -99;
while (time - $t0 < $secs) { my $t = time - $t0; my $f = int($t * 58);
  my @h = ('RIGHT'); push @h, 'B' if ($f % 10) < 5;
  push @h, 'UP' if ($f % 300) < 50; push @h, 'DOWN' if ($f % 300) >= 150 && ($f % 300) < 200;
  my $m = $f % 700; if ($m < 10) { @h = ('SELECT') } elsif ($m >= 30 && $m < 38) { @h = ('START') } elsif ($m >= 60 && $m < 66) { @h = ('B') }
  Pad::tick(@h);
  if ($t - $last >= $every) { Pad::cmd('SCREENSHOT'); $last = $t; } }
Pad::idle(0.3);
