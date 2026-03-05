#!/usr/bin/perl -w
use Cyrus::IMAP::Admin;

if (!$ARGV[0] || !$ARGV[1]) {
	die "Usage: $0 [mailbox to check] [cyrus adm passwd]\n";
} else {
    $newuser = "$ARGV[0]";
    $cyradmpwd = "$ARGV[1]";
}

my $cyrus = Cyrus::IMAP::Admin->new("localhost");
$cyrus->authenticate("login",'imap','',"cyrus",'0','10000',$cyradmpwd);

$mailbox = "user.". $newuser;

%quota = $cyrus->listquota($mailbox);

print "$quota{'STORAGE'}[1]";

