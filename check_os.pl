
# BEGIN dynamic

# This section is used/injected by dzil and not to be executed as a
# standalone program

# copy-paste from Sys::Info::Constants

die "OS unsupported\n" if $^O !~ m{linux}xmsi;

my @crucial = qw(
    /proc/cpuinfo
);

foreach my $file ( @crucial ) {
    next if -e $file;
    warn "You have a bogus Linux system which is missing $file\n";
    die "OS unsupported\n";
}

# END dynamic
