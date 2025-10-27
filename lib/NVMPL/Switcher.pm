package NVMPL::Switcher;
use strict;
use warnings;
use feature 'say';
use File::Spec;
use File::Path qw(make_path);
use File::Basename;
use NVMPL::Config;


# ---------------------------------------------------------
# Public entry point
# ---------------------------------------------------------

sub use_version {
    my ($version) = @_;
    unless ($version) {
        say "Usage: nvm-pl use <version>";
        exit 1;
    }

    $version =~ s/^V//;
    my $vtag = "v$version";

    my $cfg = NVMPL::Config->load();
    my $install_dir = $cfg->{install_dir};
    my $versions_dir = File::Spec->catdir($install_dir, 'versions');
    my $target_dir = File::Spec->catdir($versions_dir, $vtag);
    my $current_link = File::Spec->catfile($versions_dir, 'current');

    unless(-d $target_dir) {
        say "[nvm-pl] Version $vtag is not installed.";
        exit 1;
    }

    if (-l $current_link || -d $current_link) {
        unlink $current_link or warn "[nvm-pl] Could not remove existing 'current': $!";
    }

    if ($^O =~ /MSWin/) {
        _win_junction($current_link, $target_dir);
    } else {
        symlink($target_dir, $current_link)
            or die "[nvm-pl] Failed to create symlink: $!";
    }

    say "[nvm-pl] Active version is now $vtag";
    say "To use it in your shell, run:";
    if ($^O =~ /MSWin/) {
        say " set PATH=$current_link//bin;%PATH%";
    } else {
        say " export PATH=\"$current_link/bin:\$PATH\"";
    }
}


# ---------------------------------------------------------
# Helpers
# ---------------------------------------------------------

sub _win_junction {
    my ($link, $target) = @_;
    $link =~ s#/#\\#g;
    $target =~ s#/#\\#g;
    my $cmd = "cmd /C mklink /J \"$link\" \"$target\"";
    system($cmd) == 0
        or die "[nvm-pl] Failed to create junction: $!";
}

sub list_installed {
    my $cfg = NVMPL::Config->load();
    my $versions_dir = File::Spec->catdir($cfg->{install_dir}, 'versions');

    opendir(my $dh, $versions_dir) or die "Can't open $versions_dir: $!";
    my @dirs = grep { /^v\d/ && -d File::Spec->catdir($versions_dir, $_) } readdir($dh);
    closedir $dh;

    if (@dirs) {
        say "[nvm-pl] Installed versions:";
        say " $_" for sort @dirs;
    } else {
        say "[nvm-pl] No versions installed.";
    }
}

sub show_current {
    my $cfg = NVMPL::Config->load();
    my $current = File::Spec->catfile($cfg->{install_dir}, 'versions', 'current');
    if (-l $current) {
        my $target = readlink($current);
        say "[nvm-pl] Current version -> $target";
    } else {
        say "[nvm-pl] No active Node version.";
    }
}

1;