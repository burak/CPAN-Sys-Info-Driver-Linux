package Sys::Info::Driver::Linux;
use strict;
use warnings;
use vars qw( $VERSION @ISA @EXPORT );
use base qw( Exporter );

$VERSION = '0.75';
@EXPORT  = qw( proc );

use constant proc => { ## no critic (NamingConventions::Capitalization)
    loadavg  => '/proc/loadavg', # average cpu load
    cpuinfo  => '/proc/cpuinfo', # cpu information
    uptime   => '/proc/uptime',  # uptime file
    version  => '/proc/version', # os version
    meminfo  => '/proc/meminfo',
    swaps    => '/proc/swaps',
    fstab    => '/etc/fstab',    # for filesystem type of the current disk
    resolv   => '/etc/resolv.conf',
    timezone => '/etc/timezone',
    issue    => '/etc/issue',
};

1;

__END__

=head1 NAME

Sys::Info::Driver::Linux - Linux driver for Sys::Info

=head1 SYNOPSIS

    use Sys::Info::Driver::Linux;

=head1 DESCRIPTION

This is the main module in the C<Linux> driver collection.

=head1 METHODS

None.

=head1 CONSTANTS

=head2 proc

Automatically exported. Includes paths to several files.

=cut
