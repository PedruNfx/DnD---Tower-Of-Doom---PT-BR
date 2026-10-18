# RetroArch remote control: commands via UDP 55355, joypad via network RetroPad (UDP 55400)
# usage: ra.pl cmd SCREENSHOT | ask GET_STATUS | press START [ms] | hold B ms | wait ms   (ops can be chained)
# On Windows RetroArch clears remote buttons on every frame without a packet, so presses resend the state.
use strict; use warnings;
use IO::Socket::INET; use Time::HiRes qw(usleep time);
my %id = (B=>0, Y=>1, SELECT=>2, START=>3, UP=>4, DOWN=>5, LEFT=>6, RIGHT=>7, A=>8, X=>9, L=>10, R=>11);
my $cs = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => 55355, Proto => 'udp') or die $!;
my $ps = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => 55400, Proto => 'udp') or die $!;
sub cmd { my ($c, $reply) = @_; $cs->send($c); return '' unless $reply; my $buf = ''; my $rin = ''; vec($rin, fileno($cs), 1) = 1;
  if (select($rin, undef, undef, 2)) { $cs->recv($buf, 65536); } return $buf; }
sub pad { my ($bits) = @_;  # $bits: hashref of button names held
  if (!%$bits) { $ps->send(pack('l<l<l<l<S<x2', 0, 1, 0, $id{B}, 0)); return; }
  for my $b (keys %$bits) { $ps->send(pack('l<l<l<l<S<x2', 0, 1, 0, $id{$b} // die("bad button $b\n"), 1)); } }
sub hold { my ($ms, @b) = @_; my %h = map { $_ => 1 } @b; my $t0 = time; while ((time - $t0) * 1000 < $ms) { pad(\%h); usleep(4000); } pad({}); }
my @a = @ARGV;
while (@a) { my $op = shift @a;
  if ($op eq 'cmd') { cmd(shift @a) }
  elsif ($op eq 'ask') { print cmd(shift(@a), 1), "\n" }
  elsif ($op eq 'press') { my $b = shift @a; my $ms = (@a && $a[0] =~ /^\d+$/) ? shift @a : 150; hold($ms, split /\+/, $b); usleep(150000); }
  elsif ($op eq 'hold') { my $b = shift @a; my $ms = shift @a; hold($ms, split /\+/, $b); }
  elsif ($op eq 'wait') { usleep((shift @a) * 1000) }
  else { die "unknown op $op\n" } }
