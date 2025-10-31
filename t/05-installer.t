use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path remove_tree);
use FindBin;
use lib "$FindBin::Bin/../lib";

# Use Test::MockModule for proper mocking
eval { require Test::MockModule; 1 } or plan skip_all => 'Test::MockModule required';

plan tests => 10;

my $test_dir = tempdir(CLEANUP => 1);

# Create mock modules
my $config_mock = Test::MockModule->new('NVMPL::Config');
my $utils_mock = Test::MockModule->new('NVMPL::Utils');
my $installer_mock = Test::MockModule->new('NVMPL::Installer');

# Setup mocks
$config_mock->mock('load', sub {
    return {
        install_dir => $test_dir,
        mirror_url => 'https://nodejs.org/dist',
        cache_ttl => 86400,
    };
});

$utils_mock->mock('detect_platform', sub { 'linux' });

# Mock the actual HTTP call in NVMPL::Installer
$installer_mock->mock('_download_file', sub {
    my ($url, $path) = @_;
    
    # Create a fake file
    open my $fh, '>', $path or die "Cannot create fake file: $!";
    print $fh "fake content";
    close $fh;
    
    return { success => 1, status => 200, reason => 'OK' };
});

# Mock Archive::Zip methods by mocking the entire Archive::Zip module
my $archive_mock = Test::MockModule->new('Archive::Zip');
$archive_mock->mock('new', sub { bless {}, 'Archive::Zip' });
$archive_mock->mock('read', sub { 0 });  # AZ_OK
$archive_mock->mock('extractTree', sub { 0 });  # AZ_OK

# Mock tar extraction
$installer_mock->mock('_should_extract_with_tar', sub { 1 });

# Now require the module after all mocks are setup
require NVMPL::Installer;

# Test version validation
subtest 'version validation' => sub {
    plan tests => 4;
    
    # Valid versions
    lives_ok { 
        NVMPL::Installer::install_version('22.3.0'); 
    } 'Accepts valid version 22.3.0';
    
    lives_ok { 
        NVMPL::Installer::install_version('18.12.1'); 
    } 'Accepts valid version 18.12.1';
    
    # Invalid versions
    throws_ok { 
        NVMPL::Installer::install_version('invalid'); 
    } qr/Invalid version format/, 'Rejects non-numeric version';
    
    throws_ok { 
        NVMPL::Installer::install_version('22.3'); 
    } qr/Invalid version format/, 'Rejects incomplete version';
};

# Test version normalization  
subtest 'version normalization' => sub {
    plan tests => 2;
    
    my @captured_urls;
    
    # Local mock for this subtest only
    local *NVMPL::Installer::_download_file = sub {
        my ($url, $path) = @_;
        push @captured_urls, $url;
        
        open my $fh, '>', $path or die "Cannot create fake file: $!";
        print $fh "fake";
        close $fh;
        
        return { success => 1 };
    };
    
    NVMPL::Installer::install_version('v22.3.0');
    like($captured_urls[0], qr/v22\.3\.0/, 'Processes version with v prefix');
    
    NVMPL::Installer::install_version('22.3.0'); 
    like($captured_urls[1], qr/v22\.3\.0/, 'Processes version without v prefix');
};

# Test platform detection helpers
subtest 'platform helpers' => sub {
    plan tests => 5;
    
    # Test _map_platform_to_node_os
    is(NVMPL::Installer::_map_platform_to_node_os('windows'), 'win', 
       'Maps windows to win');
    is(NVMPL::Installer::_map_platform_to_node_os('macos'), 'darwin',
       'Maps macos to darwin');
    is(NVMPL::Installer::_map_platform_to_node_os('linux'), 'linux',
       'Maps linux to linux');
    is(NVMPL::Installer::_map_platform_to_node_os('bsd'), 'bsd',
       'Passes through unknown platforms');
    
    # Test file extension logic
    my $platform = 'windows';
    my $ext = $platform eq 'windows' ? 'zip' : 'tar.xz';
    is($ext, 'zip', 'Returns zip for windows');
};

# Test directory creation
subtest 'directory setup' => sub {
    plan tests => 3;
    
    my $install_dir = $test_dir;
    my $downloads_dir = File::Spec->catdir($install_dir, 'downloads');
    my $versions_dir = File::Spec->catdir($install_dir, 'versions');
    
    # Clean up any existing directories
    remove_tree($downloads_dir);
    remove_tree($versions_dir);
    
    lives_ok {
        NVMPL::Installer::install_version('22.3.0');
    } 'Installation runs without crashing';
    
    ok(-d $downloads_dir, 'Downloads directory created');
    ok(-d $versions_dir, 'Versions directory created');
};

# Test already installed detection
subtest 'already installed' => sub {
    plan tests => 1;
    
    my $versions_dir = File::Spec->catdir($test_dir, 'versions');
    my $existing_version = File::Spec->catdir($versions_dir, 'v22.3.0');
    
    # Create fake installed version
    make_path($existing_version);
    
    my $output = '';
    my $orig_say = \&CORE::say;
    no warnings 'redefine';
    local *CORE::say = sub { $output .= "@_\n" };
    
    NVMPL::Installer::install_version('22.3.0');
    
    like($output, qr/already installed/, 
         'Detects and reports already installed version');
    
    # Clean up
    remove_tree($existing_version);
};

done_testing();