die "OS unsupported\n" if $^O !~ m{linux}xmsi;

use strict;
use vars qw(%PREREQ);
use ExtUtils::MakeMaker;

do 'PREREQ' or die "Error including PREREQ: $!";

WriteMakefile(
   'NAME'         => 'Sys::Info::Driver::Linux',
   'VERSION_FROM' => 'lib/Sys/Info/Driver/Linux.pm',
   'PREREQ_PM'    => \%PREREQ,
   ($] >= 5.005 ? (
   AUTHOR   => 'Burak Gursoy <burak@cpan.org>',
   ABSTRACT => 'Linux driver for Sys::Info',
   ) : ()),
   PL_FILES => {},
);
