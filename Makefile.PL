use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'NVMPL',
    VERSION_FROM    => 'lib/NVMPL/Core.pm',
    AUTHOR          => 'Jason Hall <jason.kei.hall@gmail.com>',
    ABSTRACT        => 'A Perl-based Node Version Manager',
    LICENSE         => 'perl',
    EXE_FILES       => ['bin/nvm-pl'],
    PREREQ_PM       => {
        'Test::More'            => 0,
        'JSON::PP'              => 0,
        'HTTP::Tiny'            => 0,
        'File::HomeDir'         => 0,
        'Archive::Zip'          => 0,
        'Term::ANSIColor'       => 0,
        'Getopt::Long'          => 0,
        'File::Path'            => 0,
        'File::Spec'            => 0,
        'Exporter'              => 0,
    },

    BUILD_REQUIRES => {
        'Test::More'            => 0,
        'Test::MockModule'      => 0,
        'Test::Exception'       => 0,
        'File::Temp'            => 0,
        'FindBin'  
    },

    META_MERGE     => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/Jkhall81/nvm-pl',
                web  => 'https://github.com/Jkhall81/nvm-pl',
            },
        },
    },
);
