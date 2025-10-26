package NVMPL::Core;
use strict;
use warnings;
use feature 'say';
use NVMPL::Config;
use File::Spec;
use File::Basename;

# Haven't written these yet
# use NVMPL::Installer;
# use NVMPL::Switcher;
# use NVMPL::Utils;

my $CONFIG;

# ---------------------------------------------------------
# Entry point called from bin/nvm-pl
# ---------------------------------------------------------

sub dispatch {
    my ($command, @args) = @_;

    $CONFIG ||= NVMPL::Config->load();

    unless ($command) {
        say "No command provided. Try 'nvm-pl --help'";
        exit 1;
    }

    # Super Slick
    $command =~ s/-/_/g;

    my %commands = (
        install     => \&_install,
        use         => \&_use,
        ls          => \&_ls,
        ls_remote   => \&_ls_remote,
        current     => \&_current,
        uninstall   => \&_uninstall,
        cache       => \&_cache,
    );

    if (exists $commands{$command}) {
        $commands{$command}->(@args);
    } else {
        say "Unknown command '$command' . Try 'nvm-pl --help'";
        exit1;
    }
}

# ---------------------------------------------------------
# Command stubs (we'll implement these later)
# ---------------------------------------------------------

sub _install {
    my ($ver) = @_;
    say "[nvm-pl] Installing Node.js version: $ver";
    say "Mirror: " . NVMPL::Config::get('mirror_url');
    say "Install path: " . NVMPL::Config::get('install_dir');
}

sub _use {
    my ($ver) = @_;
    say "[nvm-pl] Activating Node.js version: $ver";
}

sub _ls {
    say "[nvm-pl] Listing installed Node.js versions (stub)";
}

sub _ls_remote {
    say "[nvm-pl] Listing available Node.js versions (stub)";
}

sub _current {
    say "[nvm-pl] Showing current active Node.js version (stub)";
}

sub _uninstall {
    my ($ver) = @_;
    say "[nvm-pl] Uninstalling Node.js version: $ver (stub)";
}

sub _cache {
    my ($subcmd) = @_;
    say "[nvm-pl] Cache command: $subcmd (stub)";
}

1;