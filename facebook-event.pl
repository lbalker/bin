#!/home/lbr/perl5/perlbrew/perls/current/bin/perl

# usage: 
# /cgi-bin/facebook-event.pl?uid=1337&key=something&partstat=ACCEPTED
# /cgi-bin/facebook-event.pl?uid=1337&key=something&partstat=TENTATIVE

# with uid and key from the url available on https://www.facebook.com/events/
# in the lower right corner (upcoming events)

BEGIN { $ENV{MOJO_LOG_LEVEL} = 'fatal'; }

use v5.10;
use strict;
use warnings;

use Mojolicious::Lite;
use Mojo::UserAgent;

app->secrets(["vkwrnkwrngkw"]);

my $fburl = "https://www.facebook.com/events/ical/upcoming/?uid=%s&key=%s";

any '/' => sub {
    my $self = shift;
    my $ua = Mojo::UserAgent->new;

	my $uid = $self->param('uid');
	my $key = $self->param('key');
	my $partstat = $self->param('partstat') // "";

	my $res = $ua->get(sprintf $fburl, $uid, $key)->result;
 
	if ($res->is_success) {
		my $vcal = $res->body;
		my $output = '';
		my $event = '';
		foreach my $line (split /\r?\n/, $vcal) {
			$line .= "\r\n";
			if (($line =~ /^BEGIN:VEVENT/) .. ($line =~ /^END:VEVENT/)) {
				$event .= $line;
				if ($line =~ /^END:VEVENT/) {
					if ($event =~ /^PARTSTAT:$partstat/mi) {
						$output .= $event;
					}
					$event = '';
				}
			}
			else {
				$output .= $line;
			}
		}

		my $h = $self->res->headers;
		$h->content_type("text/calendar;charset=utf-8");
		$h->content_disposition("attachment;filename=u$uid-$partstat.ics");
		$h->cache_control("private, no-cache, no-store, must-revalidate");
		$h->expires("Sat, 01 Jan 2000 00:00:00 GMT");

		return $self->render(text => $output);
	}
	return $self->render(text => $res->message);
};

app->start;
