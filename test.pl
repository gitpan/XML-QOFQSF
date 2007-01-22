#!/usr/bin/perl -w

use XML::QOFQSF qw(QSFParse);
use Test::Simple tests => 6;

my %obj = QSFParse("qsf-test.xml");
ok( %obj, 'successfully parsed the test file' );

my $expenses   =   $obj{'pilot_expenses'};
my $appointments = $obj{'pilot_datebook'};
ok( defined @$expenses,     "retrieved expenses." );
ok( defined @$appointments, "retrieved appointment.");

my $event_count = @$appointments;
my $exp_count   = @$expenses;
ok( $exp_count == 3, "All expenses found." );
ok( $event_count == 1, "Appointment found.");

foreach my $a (@$appointments)
{
	ok( $a->description eq "test_one", "read appointment description.");
}
