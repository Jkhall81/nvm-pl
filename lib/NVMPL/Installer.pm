package NVMPL::Installer;
use strict;
use warnings;
use feature 'say';
use HTTP::Tiny;
use File::Spec;
use File::Path qw(make_path remove_tree);
use Archive::Tar;
use Archive::Zip;
use JSON::PP qw(decode_json);
use NVMPL::Config;

# ---------------------------------------------------------
# Public entry point
# ---------------------------------------------------------

sub install_version {
    my ($version) = @_;
    unless ($version) {
        say "Usage: nvm-pl install <version>";
        exit 1;
    }

    $version =~ s/^V//;
    my $vtag = "v$version";

    my $cfg = NVMPL::Config->load();
    my $mirror = $cfg->{mirror_url};
    my $install_dir = $cfg->{install_dir};
    my $downloads = File::Spec->catdir($install_dir, 'downloads');
    my $versions = File::Spec->catdir($install_dir, 'versions');
    my $cachefile = File::Spec->catfile($install_dir, 'node_index_cache.json');

    my $os = $^O;
    my $arch = _detect_arch();
    my $ext = $os =~ /MSWin/ ? 'zip' : 'tar.xz';

    make_path($downloads) unless -d $downloads;
    make_path($versions) unless -d $versions;

    my $filename = "node-$vtag-$os-$arch.$ext";
    my $download_path = File::Spec->catfile($downloads, $filename);
    my $target_dir = File::Spec->catdir($versions, $vtag);

    if (-d $target_dir) {
        say "[nvm-pl] Node $vtag already installed.";
        return;
    }

    my $url = "$mirror/$vtag/$filename";
    say "[nvm-pl] Fetching: $url";

    unless (-f $download_path) {
        my $ua = HTTP::Tiny->new;
        my $resp = $ua->mirror($url, $download_path);
        die "Download failed: $resp->{status} $resp->{reason}\n"
            unless $resp->{success};
        say "[nvm-pl] Saved to $download_path";
    } else {
        say "[nvm-pl] Using cached file: $download_path";
    }

    say "[nvm-pl] Extracting to $target_dir";
    make_path($target_dir);

    if ($ext eq 'zip') {
        my $zip = Archive::Zip->new();
        $zip->read($download_path) == 0 or die "Failed to read zip\n";
        $zip->extractTree('', "$target_dir/");
    } else {
        my $tar = Archive::Tar->new();
        $tar->read($download_path, 1);
        $tar->extract();
    }

    say "[nvm-pl] Node $vtag installed successfully.";
}


# ---------------------------------------------------------
# Helpers
# ---------------------------------------------------------

sub _detect_arch {
    my $arch = `uname -m 2>/dev/null` || $ENV{PROCESSOR_ARCHITECTURE} || 'x64';
    chomp $arch;
    return 'x64' if $arch =~ /x86_64|amd64/i;
    return 'arm64' if $arch =~ /arm64|aarch64/i;
    return 'x86' if $arch =~ /i[3456]86/;
    return $arch;
}

1;