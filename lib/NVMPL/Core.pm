package NVMPL::Core;
use strict;
use warnings;
use feature 'say';
use NVMPL::Config;
use File::Spec;
use File::Basename;
use NVMPL::Installer;
use NVMPL::Switcher;
use NVMPL::Utils;
use NVMPL::Remote;

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
        exit 1;
    }
}

# ---------------------------------------------------------
# Command stubs (we'll implement these later)
# ---------------------------------------------------------

sub _install {
    my ($ver) = @_;
    NVMPL::Installer::install_version($ver);
}

sub _use {
    my ($ver) = @_;
    NVMPL::Switcher::use_version($ver);
}

sub _ls {
    NVMPL::Switcher::list_installed();
}

sub _ls_remote {
    my @args = @_;
    my $filter = grep { $_ eq '--lts' } @args ? 1 : 0;
    NVMPL::Remote::list_remote_versions(lts => $filter);
}

sub _current {
    NVMPL::Switcher::show_current();
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