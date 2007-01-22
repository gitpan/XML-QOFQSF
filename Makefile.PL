use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'XML::QOFQSF',
    AUTHOR              => 'Neil Williams <codehelp@debian.org>',
    VERSION_FROM        => 'lib/XML/QOFQSF.pm',
    ABSTRACT_FROM       => 'lib/XML/QOFQSF.pm',
    PL_FILES            => { },
    PREREQ_PM => {
        'Test::More' => 0,
	'XML::Simple' => 0,
	'XML::Writer' => 0,
	'Class::Struct' => 0,
	'Date::Parse' => 0,
	'Date::Format' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'XML-QOFQSF-*' },
);
