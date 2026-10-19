# dump 64KB of work RAM + a screenshot every interval: ramlog.pl count interval_s outdir
use strict; use warnings; use IO::Socket::INET; use Time::HiRes qw(time usleep);
my ($n, $iv, $dir) = @ARGV; mkdir $dir;
my $s = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => 55355, Proto => 'udp') or die;
sub ask { my $c = shift; $s->send($c); my $buf = ''; my $rin = ''; vec($rin, fileno($s), 1) = 1; $s->recv($buf, 65536) if select($rin, undef, undef, 2); return $buf; }
sub rd { my ($a, $k) = @_; my $r = ask(sprintf('READ_CORE_RAM %x %d', $a, $k)); $r =~ s/^READ_CORE_RAM \S+ //; return pack('C*', map { hex } split ' ', $r); }
my $t0 = time;
for my $i (0 .. $n - 1) { my $t = time; $s->send('SCREENSHOT'); my $out = ''; for (my $a = 0; $a < 0x10000; $a += 1024) { $out .= rd($a, 1024); }
  open my $o, '>:raw', sprintf('%s/r%03d.bin', $dir, $i) or die; print $o $out; close $o;
  printf "%03d t=%.1f len=%d\n", $i, $t - $t0, length $out; my $d = $iv - (time - $t); usleep($d * 1e6) if $d > 0; }
