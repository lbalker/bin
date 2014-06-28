#!/usr/local/bin/perl -w

use strict;
use Expect;

my $pwd = "flaf4";
my $command = "passwd";
my @params = qw( lbr2 );

$Expect::Log_Stdout = 0;

my $exp = new Expect ($command, @params);
$exp->log_file(undef);

$exp->expect(undef,
	     [ 
	      qr/password:/ =>
	      sub {  my $exp = shift;
		     $exp->send("$pwd\n");

		     exp_continue;
	      } ]
	     );

$exp->soft_close();
