package XML::QOFQSF;
use Carp;
use warnings;
use strict;
use XML::Simple;
use XML::Writer;
use Class::Struct;
use Date::Parse;
use Date::Format;
require Exporter;

use vars qw (@ISA @EXPORT_OK);
@ISA               = qw(Exporter);
@EXPORT_OK         = qw(QSFParse);

struct (Account => {
	"desc" => '$',
	"account_type" => '$',
	"code" => '$',
	"notes" => '$',
	"name" => '$',
	"guid" => '$',
	"parent_account" => 'Account',
	"tax_related_p" => '$',
	"non_standard_scu" => '$',
	"smallest_commodity_unit" => '$',
	"balance" => '$',
	"rec_bal" => '$',
	"p_acc" => '$',
});

struct (Trans => {
	"desc" => '$',
	"notes" => '$',
	"num" => '$',
	"guid" => '$',
	"date_posted" => '$',
	"date_entered" => '$',
	"type" => '$',
	"kvp_path" => '$',
	"kvp_value" => '$',
	"kvp_content" => '$',
});

struct (Split => { 
	"action" => '$',
	"memo"   => '$',
	"guid"   => '$',
	"account" => 'Account',
	"trans"  => 'Trans',
	"share_price" => '$',
	"amount" => '$',
	"date_reconciled" => '$',
	"reconcile_flag" => '$',
	"s_acc" => '$',
	"s_trans" => '$',
});

struct (gncEntry => {
	"discount_method" => '$',
	"desc" => '$',
	"action" => '$',
	"notes" => '$',
	"discount_type" => '$',
	"guid" => '$',
	"invoice_account" => 'Account',
	"bill_to" => 'Account',
	"invoice_taxable" => '$',
	"billable" => '$',
	"bill_tax_included" => '$',
	"invoice_tax_included" => '$',
	"bill_taxable" => '$',
	"qty" => '$',
	"bprice" => '$',
	"iprice" => '$',
	"date" => '$',
	"date_entered" => '$',
	"i_acc" => '$',
	"b_acc" => '$',
});

struct (gncAddress => {
	"city" => '$',
	"street" => '$',
	"fax" => '$',
	"number" => '$',
	"name" => '$',
	"email" => '$',
	"locality" => '$',
	"phone" => '$',
	"guid" => '$',
	"a_owner" => '$',
	"owner" => 'gncCustomer',
});
# problem: owner could be more than one type.
struct (gncCustomer => {
	"id" => '$',
	"notes" => '$',
	"name" => '$',
	"guid" => '$',
	"addr" => 'gncAddress',
	"shipaddr" => 'gncAddress',
	"active" => '$',
	"tax_table_override" => '$',
	"amount_of_discount" => '$',
	"amount_of_credit" => '$',
	"c_addr" => '$',
	"c_shipaddr" => '$',
});

struct (gncBillTerm => {
	"description" => '$',
	"name" => '$',
	"bill_type" => '$',
	"guid" => '$',
	"amount_of_discount" => '$',
	"cut_off" => '$',
	"number_of_days_due" => '$',
	"number_of_discounted_days" => '$',
});

struct (gncInvoice => {
	"id" => '$',
	"billing_id" => '$',
	"notes" => '$',
	"guid" => '$',
	"terms" => 'gncBillTerm',
	"account" => 'Account',
	"posted_txn" => 'Trans',
	"list_of_entries" => 'gncEntry',
	"active" => '$',
	"date_posted" => '$',
	"date_opened" => '$',
	"i_terms" => '$',
	"i_acc" => '$',
	"i_posted" => '$',
	"i_entries" => '@',	
});

struct (gncJob => {
        "id" => '$',
        "reference" => '$',
        "name" => '$',
        "guid" => '$',
        "active" => '$',
});

struct (Expense => {
	"form_of_payment" => '$',
	"distance_unit" => '$',
	"expense_vendor" => '$',
	"expense_city" => '$',
	"expense_attendees" => '$',
	"category" => '$',
	"expense_note" => '$',
	"type_of_expense" => '$',
	"guid" => '$',
	"expense_amount" => '$',
	"expense_date" => '$',
	"currency_code" => '$',
	"kvp_mnemonic" => '$',
	"kvp_string" => '$',
	"kvp_fraction" => '$',
});

struct (Contact => {
	"entryCity" => '$',
	"entryCustom4" => '$',
	"entryPhone1" => '$',
	"entryZip" => '$',
	"entryLastname" => '$',
	"entryPhone2" => '$',
	"entryNote" => '$',
	"category" => '$',
	"entryFirstname" => '$',
	"entryPhone3" => '$',
	"entryTitle" => '$',
	"entryPhone4" => '$',
	"entryCompany" => '$',
	"entryPhone5" => '$',
	"entryState" => '$',
	"entryCustom1" => '$',
	"entryAddress" => '$',
	"entryCustom2" => '$',
	"entryCountry" => '$',
	"entryCustom3" => '$',
	"guid" => '$',
});

struct (Appointment => {
	"category" => '$',
	"note" => '$',
	"repeat_type" => '$',
	"description" => '$',
	"advance_unit" => '$',
	"repeat_day" => '$',
	"repeat_week_start" => '$',
	"guid" => '$',
	"use_alarm" => '$',
	"repeat_forever" => '$',
	"transient_repeat" => '$',
	"untimed_event" => '$',
	"start_time" => '$',
	"end_time" => '$',
	"repeat_end" => '$',
	"repeat_frequency" => '$',
	"exception_count" => '$',
	"alarm_advance" => '$',
});

my %object_list;
my (@expenses, @contacts, @appointments, @splits, @accounts, @transactions, @gncinvoices, @gnccustomers, @gncbillterms, @gncaddresses, @gncentries, @gncjobs );

my $build = sub
{
	my $doc = shift;
	foreach my $key (keys (%{$doc->{book}})){
		next if ($key ne "object");
		my @object = (@{$doc->{book}->{object}});
		foreach my $g (@object)
		{
			if (($g->{type} eq 'pilot_expenses') || ($g->{type} eq 'gpe_expenses'))
			{
				my $e = new Expense;
				$e->form_of_payment($g->{'string'}->[0]->{content});
				$e->distance_unit($g->{'string'}->[1]->{content});
				$e->expense_vendor($g->{'string'}->[2]->{content});
				$e->expense_city($g->{'string'}->[3]->{content});
				$e->expense_attendees($g->{'string'}->[4]->{content});
				$e->category($g->{'string'}->[5]->{content});
				$e->expense_note($g->{'string'}->[6]->{content});
				$e->type_of_expense($g->{'string'}->[7]->{content});
				$e->guid($g->{'guid'}->[0]->{content});
				$e->expense_amount(eval($g->{'numeric'}->{content}));
				$e->expense_date(str2time($g->{'time'}->{content}));
				$e->currency_code($g->{'gint32'}->{content});
				$e->kvp_mnemonic($g->{'kvp'}->[0]->{value});
				$e->kvp_string($g->{'kvp'}->[1]->{value});
				$e->kvp_fraction($g->{'kvp'}->[2]->{value});
				push @expenses, $e;
			}
			if ($g->{type} eq 'pilot_datebook')
			{
				my $d = new Appointment;
				$d->category($g->{'string'}->[0]->{content});
				$d->note($g->{'string'}->[1]->{content});
				$d->repeat_type($g->{'string'}->[2]->{content});
				$d->description($g->{'string'}->[3]->{content});
				$d->advance_unit($g->{'string'}->[4]->{content});
				$d->repeat_day($g->{'string'}->[5]->{content});
				$d->repeat_week_start($g->{'string'}->[6]->{content});
				$d->guid($g->{'guid'}->[0]->{content});
				$d->use_alarm($g->{'boolean'}->[0]->{content});
				$d->repeat_forever($g->{'boolean'}->[1]->{content});
				$d->transient_repeat($g->{'boolean'}->[2]->{content});
				$d->untimed_event($g->{'boolean'}->[3]->{content});
				$d->start_time(str2time($g->{'time'}->[0]->{content}));
				$d->end_time(str2time($g->{'time'}->[1]->{content}));
				$d->repeat_end(str2time($g->{'time'}->[2]->{content}));
				$d->repeat_frequency($g->{'gint32'}->[0]->{content});
				$d->exception_count($g->{'gint32'}->[1]->{content});
				$d->alarm_advance($g->{'gint32'}->[2]->{content});
				push @appointments, $d;
			}
			if ($g->{type} eq 'pilot_address')
			{
				my $c = new Contact;
				$c->entryCity($g->{'string'}->[0]->{content});
				$c->entryCustom4($g->{'string'}->[1]->{content});
				$c->entryPhone1($g->{'string'}->[2]->{content});
				$c->entryZip($g->{'string'}->[3]->{content});
				$c->entryLastname($g->{'string'}->[4]->{content});
				$c->entryPhone2($g->{'string'}->[5]->{content});
				$c->entryNote($g->{'string'}->[6]->{content});
				$c->category($g->{'string'}->[7]->{content});
				$c->entryFirstname($g->{'string'}->[8]->{content});
				$c->entryPhone3($g->{'string'}->[9]->{content});
				$c->entryTitle($g->{'string'}->[10]->{content});
				$c->entryPhone4($g->{'string'}->[11]->{content});
				$c->entryCompany($g->{'string'}->[12]->{content});
				$c->entryPhone5($g->{'string'}->[13]->{content});
				$c->entryState($g->{'string'}->[14]->{content});
				$c->entryCustom1($g->{'string'}->[15]->{content});
				$c->entryAddress($g->{'string'}->[16]->{content});
				$c->entryCustom2($g->{'string'}->[17]->{content});
				$c->entryCountry($g->{'string'}->[18]->{content});
				$c->entryCustom3($g->{'string'}->[19]->{content});
				$c->guid($g->{'guid'}->[0]->{content});
				push @contacts, $c;
			}
			if ($g->{type} eq 'Trans')
			{
				my $t = new Trans;
				$t->desc($g->{'string'}->[0]->{content});
				$t->notes($g->{'string'}->[1]->{content});
				$t->num($g->{'string'}->[2]->{content});
				$t->guid($g->{'guid'}->[0]->{content});
				$t->date_posted(str2time($g->{'time'}->[0]->{content}));
				$t->date_entered(str2time($g->{'time'}->[0]->{content}));
				$t->type($g->{'character'}->{content});
				$t->kvp_path($g->{'kvp'}->{path});
				$t->kvp_value($g->{'kvp'}->{value});
				$t->kvp_content($g->{'kvp'}->{content});
				push @transactions, $t;
			}
			if ($g->{type} eq 'Account')
			{
				my $a = new Account;
				$a->desc($g->{'string'}->[0]->{content});
				$a->account_type($g->{'string'}->[1]->{content});
				$a->code($g->{'string'}->[2]->{content});
				$a->notes($g->{'string'}->[3]->{content});
				$a->name($g->{'string'}->[4]->{content});
				my $check = @{$g->{'guid'}};
				if ($check == 1)
				{
					$a->guid($g->{'guid'}->[0]->{content});
				}
				else
				{
					$a->guid($g->{'guid'}->[0]->{content});
					$a->p_acc($g->{'guid'}->[1]->{content});
				}
				$a->tax_related_p($g->{'boolean'}->[0]->{content});
				$a->non_standard_scu($g->{'boolean'}->[1]->{content});
				$a->smallest_commodity_unit($g->{'gint32'}->{content});
				push @accounts, $a;
			}
			if ($g->{type} eq 'Split')
			{
				my $s = new Split;
				if ($g->{'string'}->[0]->{type} eq 'action') {
					$s->action($g->{'string'}->[0]->{content});
					$s->memo($g->{'string'}->[1]->{content});
				}
				else {
					$s->action($g->{'string'}->[1]->{content});
					$s->memo($g->{'string'}->[0]->{content});
				}
				if ($g->{'numeric'}->[0]->{type} eq 'share-price') {
					$s->share_price(eval($g->{'numeric'}->[0]->{content}));
					$s->amount(eval($g->{'numeric'}->[1]->{content}));
				}
				else {
					$s->share_price(eval($g->{'numeric'}->[1]->{content}));
					$s->memo(eval($g->{'numeric'}->[0]->{content}));
				}
				$s->date_reconciled(str2time($g->{'date'}->{content}));
				$s->reconcile_flag($g->{'character'}->{content});
				if ($g->{'guid'}->[0]->{type} eq 'guid') {
					$s->guid($g->{'guid'}->[0]->{content});
					$s->s_acc($g->{'guid'}->[1]->{content});
					$s->s_trans($g->{'guid'}->[2]->{content});
				}
				if ($g->{'guid'}->[1]->{type} eq 'guid') {
					$s->guid($g->{'guid'}->[1]->{content});
					$s->s_acc($g->{'guid'}->[0]->{content});
					$s->s_trans($g->{'guid'}->[2]->{content});
				}
				if ($g->{'guid'}->[2]->{type} eq 'guid') {
					$s->guid($g->{'guid'}->[2]->{content});
					$s->s_acc($g->{'guid'}->[1]->{content});
					$s->s_trans($g->{'guid'}->[0]->{content});
				}
				if ($g->{'guid'}->[0]->{type} eq 'account') {
					$s->guid($g->{'guid'}->[2]->{content});
					$s->s_acc($g->{'guid'}->[0]->{content});
					$s->s_trans($g->{'guid'}->[1]->{content});
				}
				push @splits, $s;
			}
			if ($g->{type} eq 'gncEntry')
			{
				my $ge = new gncEntry;
				$ge->discount_method($g->{'string'}->[0]->{content});
				$ge->desc($g->{'string'}->[1]->{content});
				$ge->action($g->{'string'}->[2]->{content});
				$ge->notes($g->{'string'}->[3]->{content});
				$ge->discount_type($g->{'string'}->[4]->{content});
				$ge->guid($g->{'guid'}->[0]->{content});
				$ge->i_acc($g->{'guid'}->[1]->{content});
				$ge->b_acc($g->{'guid'}->[2]->{content});
				$ge->invoice_taxable($g->{'boolean'}->[0]->{content});
				$ge->billable($g->{'boolean'}->[1]->{content});
				$ge->bill_tax_included($g->{'boolean'}->[2]->{content});
				$ge->invoice_tax_included($g->{'boolean'}->[3]->{content});
				$ge->bill_taxable($g->{'boolean'}->[4]->{content});
				$ge->qty(eval($g->{'numeric'}->[0]->{content}));
				$ge->bprice(eval($g->{'numeric'}->[1]->{content}));
				$ge->iprice(eval($g->{'numeric'}->[2]->{content}));
				$ge->date(str2time($g->{'time'}->[0]->{content}));
				$ge->date_entered(str2time($g->{'time'}->[1]->{content}));
				push @gncentries, $ge;
			}
			if ($g->{type} eq 'gncInvoice')
			{
				my $gi = new gncInvoice;
				$gi->id($g->{'string'}->[0]->{content});
				$gi->billing_id($g->{'string'}->[1]->{content});
				$gi->notes($g->{'string'}->[2]->{content});
				$gi->guid($g->{'guid'}->[0]->{content});
				$gi->i_terms($g->{'guid'}->[1]->{content});
				$gi->i_acc($g->{'guid'}->[2]->{content});
				$gi->i_posted($g->{'guid'}->[3]->{content});
				# list of entries is incomplete in the upstream QOF code.
#				$gi->i_entries($g->{'guid'}->[4]->{content});
				$gi->active($g->{'boolean'}->{content});
				$gi->date_posted(str2time($g->{'date'}->[0]->{content}));
				$gi->date_opened(str2time($g->{'date'}->[1]->{content}));
				push @gncinvoices, $gi;
			}
			if ($g->{type} eq 'gncBillTerm')
			{
				my $gbt = new gncBillTerm;
				$gbt->description($g->{'string'}->[0]->{content});
				$gbt->name($g->{'string'}->[1]->{content});
				$gbt->bill_type($g->{'string'}->[2]->{content});
				$gbt->guid($g->{'guid'}->[0]->{content});
				$gbt->amount_of_discount(eval($g->{'numeric'}->{content}));
				$gbt->cut_off($g->{'gint32'}->[0]->{content});
				$gbt->number_of_days_due($g->{'gint32'}->[1]->{content});
				$gbt->number_of_discounted_days($g->{'gint32'}->[2]->{content});
				push @gncbillterms, $gbt;
			}
			if ($g->{type} eq 'gncJob')
			{
				my $gj = new gncJob;
				$gj->id($g->{'string'}->[0]->{content});
				$gj->reference($g->{'string'}->[1]->{content});
				$gj->name($g->{'string'}->[2]->{content});
				$gj->guid($g->{'guid'}->[0]->{content});
				$gj->active($g->{'boolean'}->{content});
				# need an owner record
				push @gncjobs, $gj;
			}
			if ($g->{type} eq 'gncCustomer')
			{
				my $gc = new gncCustomer;
				$gc->id($g->{'string'}->[0]->{content});
				$gc->notes($g->{'string'}->[1]->{content});
				$gc->name($g->{'string'}->[2]->{content});
				$gc->guid($g->{'guid'}->[0]->{content});
				$gc->c_addr($g->{'guid'}->[1]->{content});
				$gc->c_shipaddr($g->{'guid'}->[2]->{content});
				$gc->active($g->{'boolean'}->[0]->{content});
				$gc->tax_table_override($g->{'boolean'}->[1]->{content});
				$gc->amount_of_discount(eval($g->{'numeric'}->[0]->{content}));
				$gc->amount_of_credit(eval($g->{'numeric'}->[1]->{content}));
				push @gnccustomers, $gc;
			}
			if ($g->{type} eq 'gncAddress')
			{
				my $obj = new gncAddress;
				$obj->city($g->{'string'}->[0]->{content});
				$obj->street($g->{'string'}->[1]->{content});
				$obj->fax($g->{'string'}->[2]->{content});
				$obj->number($g->{'string'}->[3]->{content});
				$obj->name($g->{'string'}->[4]->{content});
				$obj->email($g->{'string'}->[5]->{content});
				$obj->locality($g->{'string'}->[6]->{content});
				$obj->phone($g->{'string'}->[7]->{content});
				$obj->guid($g->{'guid'}->[0]->{content});
				$obj->a_owner($g->{'guid'}->[1]->{content});
				push @gncaddresses, $obj;
			}
		}
	}
	# now cross-reference the guids
	foreach my $splt (@splits)
	{
		foreach my $t (@transactions)
		{
			$splt->trans($t) if ($t->guid eq $splt->s_trans);
		}
		foreach my $a (@accounts)
		{
			$splt->account($a) if ($a->guid eq $splt->s_acc);
		}
	}
	foreach my $t (@accounts)
	{
		foreach my $a (@accounts)
		{
			next if (!$t->p_acc);
			$t->parent_account($a) if ($a->guid eq $t->p_acc);
		}
	}
	foreach my $i (@gncinvoices)
	{
		foreach my $a (@accounts)
		{
			next if (!$i->i_acc);
			$i->account($a) if ($a->guid eq $i->i_acc);
		}
		foreach my $t (@transactions)
		{
			$i->posted_txn($t) if ($t->guid eq $i->i_posted);
		}
		foreach my $b (@gncbillterms)
		{
			next if (!$i->i_terms);
			$i->terms($b) if ($b->guid eq $i->i_terms);
		}
		# handle list of entries
	}
	foreach my $e (@gncentries)
	{
		foreach my $a (@accounts)
		{
#			$e->invoice_account($a) if ($a->guid eq $e->i_acc);
#			$e->bill_to($a) if ($a->guid eq $e->b_acc);
		}
	}
	foreach my $c (@gnccustomers)
	{
		foreach my $a (@gncaddresses)
		{
			$c->addr($a) if ($a->guid eq $c->c_addr);
			$c->shipaddr($a) if ($a->guid eq $c->c_shipaddr);
#			$a->owner($c) if ($c->guid eq $a->a_owner);
		}
	}
};

=head1 NAME

XML::QOFQSF - Parse QSF XML files created by the QOF XML backend

Support for the QOF SQLite backend will be added in due course.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Provides a single home for all QOF objects expressed as QSF XML. A similar
module for the SQLite backend is also planned. To have your QOF object included,
simply send me a sample QSF XML file. A script to create the content is also planned.

A little code snippet.

 use XML::QOFQSF qw(QSFParse);
 use Date::Parse;
 use Date::Format;

 my $file = "qsf-mileage.xml";
 my %obj = QSFParse("$file");
 my $expenses = $obj{'pilot_expenses'};

 my $exp_count = @$expenses;
 print "Status: $exp_count expenses\n";
 my $template = "%A, %o %B %Y";
 my $total_miles = 0;
 foreach my $a (@$expenses)
 {
   if ($a->type_of_expense eq "Mileage")
   {
      $total_miles += $a->expense_amount;
      print $a->expense_amount . " " . $a->distance_unit . " : ";
      print $a->expense_vendor . " " . $a->expense_city;
      print " on " . time2str($template, $a->expense_date) . "\n";
   }
 }

 print "Total: $total_miles\n";

=head1 EXPORT

XML::QOFQSF exports a single function, to parse a QSF XML file. Data from
the file is read into an array of objects of each supported type and references
to each array are added to the object_list hash using the object name as the key.

=head1 OBJECTS

pilot-qof objects (pilot_address, pilot_expenses, pilot_datebook 
and pilot_todo) are supported. gpe-expenses is also supported. Outline
support is included for cashutil objects but as cashutil is currently
unreleased, full support is pending.

L<http://qof.sourceforge.net/>

L<http://pilot-qof.sourceforge.net/>

L<http://gpe-expenses.sourceforge.net/>

L<http://cashutil.sourceforge.net/>

=head1 FUNCTIONS

=head2 QSFParse

Passed a QSF XML filename, returns a hash of array references, indexed by the
name of the objects found in the QSF XML file.

=cut

sub QSFParse {
	my $file = $_[0];
	my $xs1 = XML::Simple->new();
	my $doc = $xs1->XMLin($file, forcearray => [ 'guid' ]);
	$build->($doc);
	$object_list{'pilot_address'} = \@contacts;
	$object_list{'pilot_expenses'} = \@expenses;
	$object_list{'gpe_expenses'} = \@expenses;
	$object_list{'pilot_datebook'} = \@appointments;
	$object_list{'Split'} = \@splits;
	$object_list{'Account'} = \@accounts;
	$object_list{'Trans'} = \@transactions;
	$object_list{'gncBillTerm'} = \@gncbillterms;
	$object_list{'gncInvoice'} = \@gncinvoices;
	$object_list{'gncEntry'} = \@gncentries;
	$object_list{'gncAddress'} = \@gncaddresses;
	$object_list{'gncCustomer'} = \@gnccustomers;
	$object_list{'gncJob'} = \@gncjobs;
	return %object_list;
}

=head1 AUTHOR

Neil Williams, C<< <codehelp at debian.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-xml-qofqsf at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-QOFQSF>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::QOFQSF

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-QOFQSF>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-QOFQSF>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-QOFQSF>

=item * Search CPAN

L<http://search.cpan.org/dist/XML-QOFQSF>

=back

=head1 COPYRIGHT & LICENSE

  Copyright 2007 Neil Williams.

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the Free Software
  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

=cut

1; # End of XML::QOFQSF
