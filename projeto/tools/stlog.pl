# save a state + screenshot every interval, copying each state file: stlog.pl count interval_s statefile outdir
use strict; use warnings; use IO::Socket::INET; use Time::HiRes qw(time usleep); use File::Copy;
my ($n, $iv, $sf, $dir) = @ARGV; mkdir $dir;
my $s = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => 55355, Proto => 'udp') or die;
my $t0 = time;
for my $i (0 .. $n - 1) { my $t = time; $s->send('SAVE_STATE'); usleep(250000); $s->send('SCREENSHOT'); usleep(250000);
  copy($sf, sprintf('%s/s%03d.state', $dir, $i)) or warn "copy $i: $!\n";
  my $d = $iv - (time - $t); usleep($d * 1e6) if $d > 0; }
