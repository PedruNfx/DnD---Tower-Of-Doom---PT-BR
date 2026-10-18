package Png;
use Compress::Zlib;
sub chunk { my ($t, $d) = @_; return pack('N', length $d) . $t . $d . pack('N', crc32($t . $d)); }
# write 8-bit RGB png from array of rows (each row = string of RGB bytes)
sub write_rgb { my ($file, $w, $h, $rows) = @_;
  my $raw = join '', map { "\0" . $_ } @$rows;
  open my $o, '>:raw', $file or die; print $o "\x89PNG\r\n\x1a\n", chunk('IHDR', pack('NNCCCCC', $w, $h, 8, 2, 0, 0, 0)), chunk('IDAT', compress($raw)), chunk('IEND', ''); close $o; }
1;
