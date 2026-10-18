# Dump / poke emulated RAM through RetroArch READ_CORE_RAM / WRITE_CORE_RAM (UDP 55355)
# usage: ram.pl dump <file> [start_hex] [len_hex]  |  ram.pl write <addr_hex> <byte_hex>...  |  ram.pl read <addr_hex> <len>
use strict; use warnings; use IO::Socket::INET;
my $s = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => 55355, Proto => 'udp') or die $!;
sub ask { my $c = shift; $s->send($c); my $buf = ''; my $rin = ''; vec($rin, fileno($s), 1) = 1; $s->recv($buf, 65536) if select($rin, undef, undef, 2); return $buf; }
sub rd { my ($a, $n) = @_; my $r = ask(sprintf('READ_CORE_RAM %x %d', $a, $n)); $r =~ s/^READ_CORE_RAM \S+ //; return pack('C*', map { hex } split ' ', $r); }
my $op = shift @ARGV;
if ($op eq 'dump') { my ($f, $st, $len) = @ARGV; $st = hex($st // 0); $len = hex($len // '10000'); my $out = '';
  for (my $a = $st; $a < $st + $len; $a += 512) { my $c = rd($a, 512); die sprintf("short read at %X\n", $a) if length $c != 512; $out .= $c; }
  open my $o, '>:raw', $f or die; print $o $out; close $o; printf "dumped %X bytes\n", length $out; }
elsif ($op eq 'read') { my ($a, $n) = @ARGV; print join(' ', map { sprintf '%02X', $_ } unpack('C*', rd(hex $a, $n))), "\n"; }
elsif ($op eq 'write') { my ($a, @b) = @ARGV; print ask(sprintf('WRITE_CORE_RAM %x %s', hex $a, join(' ', @b))), "\n"; }
