package Sys::Info::Driver::Linux::OS::Distribution;
use strict;
use warnings;
use constant STD_RELEASE => 'lsb-release';
use base qw( Sys::Info::Base );
use Carp qw( croak );
use Sys::Info::Driver::Linux;
use Sys::Info::Constants qw( :linux );

our $VERSION = '0.73';

my %ORIGINAL_RELEASE = qw(
    arch-release            arch
    debian_version          debian
    debian_release          debian
    gentoo-release          gentoo
    mandrake-release        mandrake
    mandrakelinux-release   mandrakelinux
    redhat-release          redhat
    redhat_version          redhat
    slackware-version       slackware
    slackware-release       slackware
    SuSE-release            suse
);

my %DERIVED_RELEASE = qw(
    adamantix_version       adamantix
    conectiva-release       conectiva
    fedora-release          fedora
    immunix-release         immunix
    knoppix-version         knoppix
    libranet_version        libranet
    pardus-release          pardus
    redflag-release         redflag
    tinysofa-release        tinysofa
    trustix-release         trustix
    turbolinux-release      turbolinux
    va-release              va-linux
    yellowdog-release       yellowdog
    yoper-release           yoper
);

my %version_match = (
    'gentoo'    => 'Gentoo Base System version (.*)',
    'debian'    => '(.+)',
    'suse'      => 'VERSION = (.*)',
    'fedora'    => 'Fedora Core release (\d+) \(',
    'redflag'   => 'Red Flag (?:Desktop|Linux) (?:release |\()(.*?)(?: \(.+)?\)',
    'redhat'    => 'Red Hat Linux release (.*) \(',
    'slackware' => '^Slackware (.+)$',
    'pardus'    => '^Pardus (.+)$',
);

my %DISTROFIX = qw( suse SUSE );

my $EDITION   = {
    # taken from wikipedia
    ubuntu => {
         '4.10' => 'Warty Warthog',
         '5.04' => 'Hoary Hedgehog',
         '5.10' => 'Breezy Badger',
         '6.06' => 'Dapper Drake',
         '6.10' => 'Edgy Eft',
         '7.04' => 'Feisty Fawn',
         '7.10' => 'Gutsy Gibbon',
         '8.04' => 'Hardy Heron',
         '8.10' => 'Intrepid Ibex',
         '9.04' => 'Jaunty Jackalope',
         '9.10' => 'Karmic Koala',
	'10.04' => 'Lucid Lynx',
    },
    debian => {
        '1.1' => 'buzz',
        '1.2' => 'rex',
        '1.3' => 'bo',
        '2.0' => 'hamm',
        '2.1' => 'slink',
        '2.2' => 'potato',
        '3.0' => 'woody',
        '3.1' => 'sarge',
        '4.0' => 'etch',
        '5.0' => 'lenny',
        '6.0' => 'squeeze',
    },
    fedora => {
         '1' => 'Yarrow',
         '2' => 'Tettnang',
         '3' => 'Heidelberg',
         '4' => 'Stentz',
         '5' => 'Bordeaux',
         '6' => 'Zod',
         '7' => 'Moonshine',
         '8' => 'Werewolf',
         '9' => 'Sulphur',
        '10' => 'Cambridge',
        '11' => 'Leonidas',
        '12' => 'Constantine',
        '13' => 'Goddard',
    },
    mandriva => {
           '5.1' => 'Venice',
           '5.2' => 'Leeloo',
           '5.3' => 'Festen',
           '6.0' => 'Venus',
           '6.1' => 'Helios',
           '7.0' => 'Air',
           '7.1' => 'Helium',
           '7.2' => 'Odyssey',
           '8.0' => 'Traktopel',
           '8.1' => 'Vitamin',
           '8.2' => 'Bluebird',
           '9.0' => 'Dolphin',
           '9.1' => 'Bamboo',
           '9.2' => 'FiveStar',
          '10.0' => 'Community',
          '10.1' => 'Community',
          '10.1' => 'Official',
          '10.2' => 'Limited Edition 2005',
        '2006.0' => '2006',
        '2007'   => '2007',
        '2007.1' => '2007 Spring',
        '2008.0' => '2008',
        '2008.1' => '2008 Spring',
        '2009.0' => '2009',
        '2009.1' => '2009 Spring',
        '2010.0' => '2010',
    },
};

my $MANUFACTURER = {
    # taken from wikipedia
    ubuntu    => 'Canonical Ltd. / Ubuntu Foundation',
    centos    => 'Lance Davis',
    fedora    => 'Fedora Project',
    debian    => 'Debian Project',
    mandriva  => 'Mandriva',
    knoppix   => 'Klaus Knopper',
    gentoo    => 'Gentoo Foundation',
    suse      => 'Novell',
    slackware => 'Patrick Volkerding',
};

my %DEBIAN_VFIX = (
    # we get the version as "lenny/sid" for example
    buzz   => '1.1',
    rex    => '1.2',
    bo     => '1.3',
    hamm   => '2.0',
    slink  => '2.1',
    potato => '2.2',
    woody  => '3.0',
    sarge  => '3.1',
    etch   => '4.0',
    lenny  => '5.0',
);

my $EDITION_SUPPORT      = join q{|}, keys %{ $EDITION      };
my $MANUFACTURER_SUPPORT = join q{|}, keys %{ $MANUFACTURER };

sub new {
    my $class = shift;
    my $self = {
        'DISTRIB_ID'          => q{},
        'DISTRIB_RELEASE'     => q{},
        'DISTRIB_CODENAME'    => q{},
        'DISTRIB_DESCRIPTION' => q{},
        'release_file'        => q{},
        'pattern'             => q{},
	PROBE   => undef,
	RESULTS => undef,
    };
    bless $self, $class;
    $self->_initial_probe;
    return $self;
}

sub name       { return shift->{RESULTS}{name}    }
sub version    { return shift->{RESULTS}{version} }
sub edition    { return shift->{RESULTS}{edition} }
sub kernel     { return shift->{PROBE}{kernel}            }
sub build      { return shift->{PROBE}{build}             }
sub build_date { return shift->{PROBE}{build_date}        }
sub manufacturer {
    my $self = shift;
    return $self->name =~ m{ ($MANUFACTURER_SUPPORT) }xmsi
            ? $MANUFACTURER->{ lc $1 }
	    : undef;
}

sub _probe {
    my $self = shift;
    return $self->{RESULTS} if $self->{RESULTS};
    $self->{RESULTS} = {};
    $self->{RESULTS}->{name}    = $self->_probe_name;
    $self->{RESULTS}->{version} = $self->_probe_version;
    # this has to be last, since this also modifies the two above
    $self->{RESULTS}->{edition} = $self->_probe_edition;
    return $self->{RESULTS};
}

sub _probe_name {
    my $self = shift;
    my $distro = $self->_get_lsb_info;
    return $distro if $distro;
    return $self->_probe_release( \%DERIVED_RELEASE  )
        || $self->_probe_release( \%ORIGINAL_RELEASE );
}

sub _probe_release {
    my($self, $r) = @_;
    foreach my $id ( keys %{ $r } ) {
        if ( -f "/etc/$id" && !-l _ ){
            $self->{'DISTRIB_ID'}   = $r->{$id};
            $self->{'release_file'} = $id;
            return $self->{'DISTRIB_ID'};
        }
    }
    return;
}

sub _probe_version {
    my $self = shift;
    my $release = $self->_get_lsb_info('DISTRIB_RELEASE');
    return $release if $release;
    if (! $self->{'DISTRIB_ID'}){
         $self->name() or croak 'No version because no distribution';
    }
    $self->{'pattern'} = $version_match{$self->{'DISTRIB_ID'}};
    $release = $self->_get_file_info();
    $self->{'DISTRIB_RELEASE'} = $release;
    return $release;
}

sub _probe_edition {
    my $self = shift;
    my $p    = $self->{PROBE};

    if ( my $dn = $self->name ) {
        $dn  = $DISTROFIX{$dn} || ucfirst $dn;
        $dn .= ' Linux';
	$self->{RESULTS}{name}    = $dn;
    }
    else {
	$self->{RESULTS}{name}    = $p->{distro};
	$self->{RESULTS}{version} = $p->{kernel};
    }

    my $name = $self->name;
    my $version = $self->version;

    my $edition;
    if ( $name =~ m{ ($EDITION_SUPPORT) }xmsi ) {
        my $id = lc $1;
        $edition = $EDITION->{ $id }{ $version };
    }

    if ( ! $edition && $version && $version !~ m{[0-9]}xms ) {
        if ( $name =~ /Debian/xmsi ) {
            my @buf = split m{/}xms, $version;
            if ( my $test = $DEBIAN_VFIX{ lc $buf[0] } ) {
                # Debian version comes as the edition name
                $edition = $version;
                $self->{RESULTS}{version} = $test;
            }
        }
    }

    return $edition;
}

sub _initial_probe {
    my $self    = shift;
    my $version = q{};

    if (  -e proc->{'version'} && -f _) {
        $version =  $self->trim(
                        $self->slurp(
                            proc->{'version'},
                            'I can not open linux version file %s for reading: '
                        )
                    );
    }

    my($str, $build_date) = split /\#/xms, $version;
    my($kernel, $distro)  = (q{},q{});
    #$build_date = "1 Fri Jul 23 20:48:29 CDT 2004';";
    #$build_date = "1 SMP Mon Aug 16 09:25:06 EDT 2004";
    $build_date = q{} if not $build_date; # running since blah thingie
    # format: 'Linux version 1.2.3 (foo@bar.com)'
    # format: 'Linux version 1.2.3 (foo@bar.com) (gcc 1.2.3)'
    # format: 'Linux version 1.2.3 (foo@bar.com) (gcc 1.2.3 (Redhat blah blah))'
    if ( $str =~ LIN_RE_LINUX_VERSION ) {
        $kernel = $1;
        if ( $distro = $self->trim( $2 ) ) {
            if ( $distro =~ m{ \s\((.+?)\)\) \z }xms ) {
                $distro = $1;
            }
        }
    }

    $distro = 'Linux' if ! $distro || $distro =~ m{\(gcc}xms;

    # kernel build date
    $build_date = $self->date2time($build_date) if $build_date;
    my $build = $build_date || q{};
    $build = scalar localtime $build if $build;
    $self->{PROBE} = {
	version    => $version,
	kernel     => $kernel,
	build      => $build,
	build_date => $build_date,
	distro     => $distro,
    };
    $self->_probe;
    return;
}

sub _get_lsb_info {
    my $self  = shift;
    my $field = shift || 'DISTRIB_ID';
    my $tmp   = $self->{'release_file'};

    if ( -r '/etc/' . STD_RELEASE ) {
        $self->{'release_file'} = STD_RELEASE;
        $self->{'pattern'} = $field . '=(.+)';
        my $info = $self->_get_file_info();
        if ($info){
            $self->{$field} = $info;
            return $info;
        }
    }

    $self->{release_file} = $tmp;
    $self->{pattern}      = q{};
    return;
}

sub _get_file_info {
    my $self = shift;
    my $file = '/etc/' . $self->{'release_file'};
    open my $FH, '<', $file or croak "Cannot open file: $file";
    my $rv;
    while (<$FH>){
        chomp $_;
        my($info) = $_ =~ m/$self->{pattern}/;
        if ( $info ) {
	    $rv = "\L$info";
	    last;
	}
    }
    close $FH or croak "Can't close FH($file): $!";
    return $rv;
}

1;

__END__


=head1 NAME

Sys::Info::Driver::Linux::OS::Distribution - Linux distribution probe

=head1 SYNOPSIS

    use Sys::Info::Driver::Linux::OS::Distribution;
    my $distro = Sys::Info::Driver::Linux::OS::Distribution->new;
    my $name   = $distro->name;
    if( $name ) {
        my $version = $distro->version;
        print "you are running $distro, version $version\n";
    }
    else {
        print "distribution unknown\n";
    }

=head1 DESCRIPTION

This is a simple module that tries to guess on what linux distribution
we are running by looking for release's files in /etc.  It now looks for
'lsb-release' first as that should be the most correct and adds ubuntu support.
Secondly, it will look for the distro specific files.

It currently recognizes slackware, debian, suse, fedora, redhat, turbolinux,
yellowdog, knoppix, mandrake, conectiva, immunix, tinysofa, va-linux, trustix,
adamantix, yoper, arch-linux, libranet, gentoo, ubuntu and redflag.

It has function to get the version for debian, suse, redhat, gentoo, slackware,
redflag and ubuntu(lsb). People running unsupported distro's are greatly
encouraged to submit patches.

=head1 METHODS

=head2 build

=head2 build_date

=head2 edition

=head2 kernel

=head2 manufacturer

=head2 name

=head2 new

=head2 version

=head1 TODO

Add the capability of recognize the version of the distribution for all
recognized distributions.

=head1 Linux::Distribution AUTHORS

Some parts of this module were originally taken from C<Linux::Distribution>
and it's authors are:

    Alberto Re       E<lt>alberto@accidia.netE<gt>
    Judith Lebzelter E<lt>judith@osdl.orgE<gt>
    Alexandr Ciornii E<lt>alexchorny@gmail.com<gt>

=cut
