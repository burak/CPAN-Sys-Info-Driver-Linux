#!/usr/bin/env perl -w
use strict;
use Data::Dumper;
use Test::More qw( no_plan );
use constant NA => 'N/A';
use Sys::Info::OS;
use Sys::Info::Device;

my $BUF  = "\n      %s";

# Just try the interface methods
# ... see if they all exist

my $os   = Sys::Info::OS->new;
my $cpu  = Sys::Info::Device->new('CPU');

print  "\n[Sys::Info::OS]\n";

printf "OS name          : %s\n"       , $os->name;
printf "OS long name     : %s\n"       , $os->name( long => 1 );
printf "OS long name+ed  : %s\n"       , $os->name( long => 1, edition => 1 );
printf "OS edition       : %s\n"       , $os->edition                 || NA;
printf "OS version       : %s\n"       , $os->version;
printf "OS build         : %s\n"       , $os->build;
printf "OS uptime        : %s\n"       , up($os->uptime)              || NA;
printf "Tick count       : %s\n"       , tick($os->tick_count);
printf "Node name        : %s\n"       , $os->node_name               || NA;
printf "Domain name      : %s\n"       , $os->domain_name             || NA;
printf "Workgroup        : %s\n"       , $os->workgroup               || NA;
printf "User name        : %s\n"       , $os->login_name              || NA;
printf "Real user name   : %s\n"       , $os->login_name( real => 1 ) || NA;
printf "Windows          : %s\n"       , $os->is_windows    ? 'yes' : 'no';
printf "Windows          : %s\n"       , $os->is_win32      ? 'yes' : 'no';
printf "Windows          : %s\n"       , $os->is_win        ? 'yes' : 'no';
printf "Windows NT       : %s\n"       , $os->is_winnt      ? 'yes' : 'no';
printf "Windows 9x       : %s\n"       , $os->is_win95      ? 'yes' : 'no';
printf "Windows 9x       : %s\n"       , $os->is_win9x      ? 'yes' : 'no';
printf "Linux            : %s\n"       , $os->is_linux      ? 'yes' : 'no';
printf "Linux            : %s\n"       , $os->is_lin        ? 'yes' : 'no';
printf "Unknown OS       : %s\n"       , $os->is_unknown    ? 'yes' : 'no';
printf "Administrator    : %s\n"       , $os->is_root       ? 'yes' : 'no';
printf "Administrator    : %s\n"       , $os->is_admin      ? 'yes' : 'no';
printf "Administrator    : %s\n"       , $os->is_admin_user ? 'yes' : 'no';
printf "Administrator    : %s\n"       , $os->is_adminuser  ? 'yes' : 'no';
printf "Administrator    : %s\n"       , $os->is_root_user  ? 'yes' : 'no';
printf "Administrator    : %s\n"       , $os->is_super_user ? 'yes' : 'no';
printf "Administrator    : %s\n"       , $os->is_superuser  ? 'yes' : 'no';
printf "Administrator    : %s\n"       , $os->is_su         ? 'yes' : 'no';
printf "Logon Server     : %s\n"       , $os->logon_server    || NA;
printf "Time Zone        : %s\n"       , $os->tz              || NA;
printf "File system      : $BUF\n"     , dumper( FS   => { $os->fs   } );
printf "OS meta          : $BUF\n"     , dumper( META => { $os->meta } );

printf "Windows CD Key   : %s\n"       , eval { $os->cdkey }                    || NA;
printf "MSO CD Key       : %s\n"       , eval {($os->cdkey( office => 1 ))[0] } || NA;

print  "\n[Sys::Info::CPU]\n";

printf "CPU Name         : %s\n"       , scalar($cpu->identify) || NA;
printf "CPU Speed        : %s MHz\n"   , $cpu->speed            || NA;
printf "CPU load average : %s\n"       , $cpu->load             || NA;
printf "Number of CPUs   : %s\n"       , $cpu->count            || NA;
printf "CPU probe        : $BUF\n"     , dumper(CPU => $cpu->identify);

ok(1);

#------------------------------------------------------------------------------#

sub dumper {
   my $n   = shift;
   my $ref = (@_ == 1) ? shift : \@_;
   Data::Dumper->Dump([$ref], ['*'.$n])
}

sub up {
   my $up = shift || return 0;
   scalar(localtime $up);
}

sub tick {
   my $tick = shift || return 0;
   eval { require Time::Elapsed; };
   return sprintf( "%.2f days", $tick / (60*60*24) ) if $@;
   return Time::Elapsed::elapsed( $tick );
}

1;
