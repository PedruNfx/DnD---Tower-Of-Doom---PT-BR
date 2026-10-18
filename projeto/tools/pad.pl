package Pad;
# Network RetroPad driver. RetroArch reads ONE packet per frame and (on Windows) clears all buttons on a
# frame without a packet, so we send exactly one packet per tick (~58 Hz): pending changes first, else a keepalive.
use strict; use warnings; use IO::Socket::INET; use Time::HiRes qw(usleep time);
our %ID = (B=>0, Y=>1, SELECT=>2, START=>3, UP=>4, DOWN=>5, LEFT=>6, RIGHT=>7, A=>8, X=>9);
my $ps = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => 55400, Proto => 'udp') or die;
my $cs = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => 55355, Proto => 'udp') or die;
my %cur; my $ka = 0; my $next = time;
sub send1 { my ($b, $s) = @_; $ps->send(pack('l<l<l<l<S<x2', 0, 1, 0, $ID{$b}, $s)); }
sub cmd { $cs->send($_[0]); }
# one tick with the desired held set
sub tick { my %want = map { $_ => 1 } @_;
  my @rel = grep { !$want{$_} } sort keys %cur; my @prs = grep { !$cur{$_} } sort keys %want;
  if (@rel) { send1($rel[0], 0); delete $cur{$rel[0]}; }
  elsif (@prs) { send1($prs[0], 1); $cur{$prs[0]} = 1; }
  else { my @h = sort keys %cur; if (@h) { send1($h[$ka++ % @h], 1) } else { send1('Y', 0) } }
  $next += 1 / 58; my $d = $next - time; if ($d > 0) { usleep($d * 1e6) } else { $next = time } }
sub hold { my ($secs, @b) = @_; my $t = time; tick(@b) while time - $t < $secs; }
sub idle { my $secs = shift; my $t = time; tick() while time - $t < $secs; }
1;
