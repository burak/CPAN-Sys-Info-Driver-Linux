package Sys::Info::Driver::Linux::Device::CPU;
use strict;
use vars qw($VERSION);
use base qw(Sys::Info::Base);
use Sys::Info::Driver::Linux;
use Unix::Processors;
use POSIX ();
use Sys::Info::Constants qw( LIN_MACHINE );

$VERSION = '0.69_01';

sub identify {
    my $self = shift;

    if ( ! $self->{META_DATA} ) {
        my $mach = (POSIX::uname)[LIN_MACHINE];
        my $arch = $mach =~ m{ i [0-9] 86 }xmsi ? 'x86'
                 : $mach =~ m{ ia64       }xmsi ? 'IA64'
                 : $mach =~ m{ x86_64     }xmsi ? 'AMD-64'
                 :                                 $mach
                 ;

        my @raw = split m{\n\n}xms,
                        $self->trim( $self->slurp( proc->{cpuinfo} ) );
        $self->{META_DATA} = [];
        foreach my $e ( @raw ) {
            push @{ $self->{META_DATA} },
                  { $self->_parse_cpuinfo($e), architecture => $arch };
        }
    }

    return $self->_serve_from_cache(wantarray);
}

sub load {
    my $self  = shift;
    my $level = shift;
    my @loads = split /\s+/, $self->slurp( proc->{loadavg} );
    return $loads[$level];
}

sub _parse_cpuinfo {
    my $self = shift;
    my $raw  = shift || die "Parser called without data";
    my($k, $v);
    my %cpu;
    foreach my $line (split /\n/, $raw) {
        ($k, $v) = split /\s+:\s+/, $line;
        $cpu{$k} = $v;
    }

    my @flags = split /\s+/, $cpu{flags};
    my %flags = map { $_ => 1 } @flags;
    my $up    = Unix::Processors->new;
    (my $name  = $cpu{'model name'}) =~ s[ \s{2,} ][ ]xms;

    return(
        processor_id                 => $cpu{processor},
        data_width                   => $flags{lm} ? 64 : 32, # guess
        address_width                => $flags{lm} ? 64 : 32, # guess
        bus_speed                    => undef,
        speed                        => $cpu{'cpu MHz'},
        name                         => $name,
        family                       => $cpu{'cpu family'},
        manufacturer                 => $cpu{vendor_id},
        model                        => $cpu{model},
        stepping                     => $cpu{stepping},
        number_of_cores              => $cpu{'cpu cores'} || $up->max_physical,
        number_of_logical_processors => $up->max_online,
        L2_cache                     => {max_cache_size => $cpu{'cache size'}},
        flags                        => @flags ? [ @flags ] : undef,
    );
}

1;

__END__

=head1 NAME

Sys::Info::Driver::Linux::Device::CPU - Linux CPU Device Driver

=head1 SYNOPSIS

-

=head1 DESCRIPTION

Identifies the CPU with L<Unix::Processors>, L<POSIX> and C<< /proc >>.

=head1 METHODS

=head2 identify

See identify in L<Sys::Info::Device::CPU>.

=head2 load

See load in L<Sys::Info::Device::CPU>.

=head1 SEE ALSO

L<Sys::Info>,
L<Sys::Info::Device::CPU>,
L<Unix::Processors>, L<POSIX>,
proc filesystem.

=head1 AUTHOR

Burak Gürsoy, E<lt>burakE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2006-2009 Burak Gürsoy. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself, either Perl version 5.8.8 or, 
at your option, any later version of Perl 5 you may have available.

=cut
