package Sys::Info::Driver::Linux::OS::Distribution;
use strict;
use warnings;
use constant STD_RELEASE => 'lsb-release';
use base qw( Sys::Info::Base );
use Carp qw( croak );
use Sys::Info::Driver::Linux;
use Sys::Info::Constants qw( :linux );
use Sys::Info::Driver::Linux::OS::Distribution::Conf;
use File::Spec;

our $VERSION = '0.73';

# XXX: <REMOVE>
my $RELX = sub {
    my $master = shift;
    my $t = sub {
        my($k, $v) = @_;
	return map { $_ => $v} ref $k ? @{$k} : ($k);
    };
    map  { $t->($CONF{$_}->{$master}, $_ ) }
    grep {      $CONF{$_}->{$master}       }
    keys %CONF
};

my %ORIGINAL_RELEASE = $RELX->('release');
my %DERIVED_RELEASE  = $RELX->('release_derived');
#</REMOVE>

sub new {
    my $class = shift;
    my $self  = {
        DISTRIB_ID          => q{},
        DISTRIB_RELEASE     => q{},
        DISTRIB_CODENAME    => q{},
        DISTRIB_DESCRIPTION => q{},
        release_file        => q{},
        pattern             => q{},
	PROBE               => undef,
	RESULTS             => undef,
    };
    bless $self, $class;
    $self->_initial_probe;
    return $self;
}

sub raw_name     { return shift->{RESULTS}{raw_name} }
sub name         { return shift->{RESULTS}{name}     }
sub version      { return shift->{RESULTS}{version}  }
sub edition      { return shift->{RESULTS}{edition}  }
sub kernel       { return shift->{PROBE}{kernel}     }
sub build        { return shift->{PROBE}{build}      }
sub build_date   { return shift->{PROBE}{build_date} }
sub manufacturer {
    my $self = shift;
    my $slot = $CONF{ lc $self->raw_name } || return;
    return if ! exists $slot->{manufacturer};
    return $slot->{manufacturer};
}

sub _probe {
    my $self = shift;
    return $self->{RESULTS} if $self->{RESULTS};
    $self->{RESULTS}           = {};
    $self->{RESULTS}{name}     = $self->_probe_name;
    $self->{RESULTS}{raw_name} = $self->{RESULTS}{name};
    $self->{RESULTS}{version}  = $self->_probe_version;
    # this has to be last, since this also modifies the two above
    $self->{RESULTS}{edition}  = $self->_probe_edition;
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
	# we can't use "-l _" here. it'll die on some systems
	# XXX: check if -l check is really necessary
        if ( -f "/etc/$id" && !-l "/etc/$id" ){
            $self->{DISTRIB_ID}   = $r->{ $id };
            $self->{release_file} = $id;
            return $self->{DISTRIB_ID};
        }
    }
    return;
}

sub _probe_version {
    my $self = shift;
    my $release = $self->_get_lsb_info('DISTRIB_RELEASE');
    return $release if $release;
    if ( ! $self->{DISTRIB_ID} ){
        croak 'No version because no distribution' if ! $self->name;
    }
    my $slot         = $CONF{ lc $self->{DISTRIB_ID} };
    $self->{pattern} = exists $slot->{version_match} ? $slot->{version_match} : q{};
    $release         = $self->_get_file_info;
    $self->{DISTRIB_RELEASE} = $release;
    return $release;
}

sub _probe_edition {
    my $self = shift;
    my $p    = $self->{PROBE};

    if ( my $dn = $self->name ) {
	my $slot = $CONF{ $dn };
        $dn  = exists $slot->{name} ? $slot->{name} : ucfirst $dn;
        $dn .= ' Linux';
	$self->{RESULTS}{name}    = $dn;
    }
    else {
	$self->{RESULTS}{name}    = $p->{distro};
	$self->{RESULTS}{version} = $p->{kernel};
    }

    my $name     = $self->name;
    my $raw_name = $self->raw_name;
    my $version  = $self->version;
    my $slot     = $CONF{$raw_name} || return;
    my $edition  = exists $slot->{edition} ? $slot->{edition}{ $version } : undef;

    if ( ! $edition && $version && $version !~ m{[0-9]}xms ) {
        if ( $name =~ /debian/xmsi ) {
            my @buf = split m{/}xms, $version;
            if ( my $test = $CONF{debian}->{vfix}{ lc $buf[0] } ) {
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

    if (  -e proc->{version} && -f _) {
        $version =  $self->trim(
                        $self->slurp(
                            proc->{version},
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
    my $build   = $build_date ? localtime $build_date : q{};

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
    my $tmp   = $self->{release_file};

    if ( -r File::Spec->catfile( '/etc', STD_RELEASE ) ) {
        $self->{release_file} = STD_RELEASE;
        $self->{pattern}      = $field . '=(.+)';
        my $info = $self->_get_file_info;
        return $self->{$field} = $info if $info;
    }

    $self->{release_file} = $tmp;
    $self->{pattern}      = q{};
    return;
}

sub _get_file_info {
    my $self = shift;
    my $file = File::Spec->catfile( '/etc', $self->{release_file} );
    require IO::File;
    my $FH = IO::File->new;
    $FH->open( $file, '<' ) || croak "Cannot open $file: $!";
    my @raw = <$FH>;
    $FH->close || croak "Can't close FH($file): $!";
    my $rv;
    foreach my $line ( @raw ){
        chomp $line;
	## no critic (RequireExtendedFormatting)
        my($info) = $line =~ m/$self->{pattern}/ms;
        if ( $info ) {
	    $rv = "\L$info";
	    last;
	}
    }
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

=head2 raw_name

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
