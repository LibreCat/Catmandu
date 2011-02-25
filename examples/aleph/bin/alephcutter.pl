#!/usr/bin/env perl

my $file = shift;
my $max  = shift || 1000;

die "usage: $0 file [max]" unless -r $file;

my $count = 0;
open(IN,$file);
my $prev_id = undef;

print STDERR "$file.$count...\n";
open(OUT,">$file.$count");

while(<IN>) {
  next unless (/\S+/);
  my $sysid = substr($_,0,9);

  if ($prev_id && $prev_id ne $sysid) {
     $count++;

     if ($count % $max == 0) {
	print STDERR "$file.$count...\n";
	close(OUT);
	open(OUT,">$file.$count");
     } 
  }

  print OUT $_;

  $prev_id = $sysid;
}
close(OUT);
close(IN);
