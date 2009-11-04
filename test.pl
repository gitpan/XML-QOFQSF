#!/usr/bin/perl

use warnings;
use XML::QOFQSF qw(QSFParse);
use Test::Simple tests => 18;

my %obj = QSFParse("qsf-test.xml");
ok( %obj, ' successfully parsed the test file' );

my $expenses   =   $obj{'pilot_expenses'};
my $appointments = $obj{'pilot_datebook'};
ok( defined @$expenses,     " retrieved expenses." );
ok( defined @$appointments, " retrieved appointment.");

my $event_count = @$appointments;
my $exp_count   = @$expenses;
ok( $exp_count == 3, " All expenses found." );
ok( $event_count == 1, " Appointment found.");

foreach my $a (@$appointments)
{
	ok( $a->description eq "test_one", " read appointment description.");
	ok ($a->transient_repeat eq "false", " read boolean from appointment.");
	ok ($a->category eq "CPAN", " read category from appointment.");
	ok ($a->start_time == 1162630800, " read start time from appointment.");
}

foreach my $e (@$expenses)
{
	if ($e->type_of_expense eq "Mileage")
	{
		ok ($e->expense_amount == 82, "read mileage from expenses");
		ok ($e->distance_unit eq "Miles", "read distance unit from expenses");
		ok ($e->expense_city eq "test_one", "read expense city");
	}
	if ($e->type_of_expense eq "Incidentals")
	{
		ok ($e->form_of_payment eq "Prepaid", "read form of payment from expenses");
		ok ($e->kvp_mnemonic eq "GBP", "read currency mnemonic from expenses");
		ok ($e->expense_date eq "1162598400", "read date from expenses");
	}
	if ($e->type_of_expense eq "Parking")
	{
		ok ($e->expense_amount == 5, "read parking from expenses");
		ok ($e->category eq "CPAN", "read category from expenses");
		ok ($e->currency_code == 22, "read currency_code from expenses");
	}
}
