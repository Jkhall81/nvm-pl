use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'NVMPL',
    VERSION_FROM    => 'bin/nvm-pl',
    AUTHOR          => 'Jason Hall <jason.kei.hall@gmail.com>',
    ABSTRACT        => 'A Perl-based Node Version Manager',
    LICENSE         => 'perl',
    EXE_FILES       => ['bin/nvm-pl'],
    PREREQ_PM       => {
        'Test::More'            => 0,
        'JSON::PP'              => 0,
        'HTTP::Tiny'            => 0,
        'File::HomeDir'         => 0,
        'Archive::Tar'          => 0,
        'Archive::Zip'          => 0,
        'Term::ANSIColor'       => 0,
        'Getopt::Long'          => 0,
    },
);