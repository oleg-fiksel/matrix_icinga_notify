#!/usr/bin/perl
use strict;
use warnings;

# Unicode
use utf8;
binmode(STDIN, ":encoding(UTF-8)");
binmode(STDOUT, ":encoding(UTF-8)");
binmode(STDERR, ":encoding(UTF-8)");

our $version = '1.0.0';

# core modules
use Getopt::Std;

use FindBin qw($Bin);
use lib $Bin.'/lib';

# CPAN modules
use LWP;
use Mojo::JSON qw(decode_json encode_json);

# debug
#use warnings;
#use diagnostics;
# debug

use Env;

my $opts={};

getopts('sdc:', $opts);

usage() if !defined $opts->{c};

die "Can't read config $opts->{c}!"
	if !-r $opts->{c};

my $message = join "", <STDIN>;

die 'Not message is specified! Specify your message via STDIN.'
	if !defined $message;

my $config = read_config($opts->{c});

# disable SSL cert verification
# if this doesn't work you need to install the following packages:
#    IO::Socket::SSL LWP LWP::Protocol::https
$ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = 'IO::Socket::SSL'
	if $opts->{s};

exit(main());

sub usage{
	print <<EOF;

Icinga matrix notifier version $version

Usage:
	echo 'Message text (also <strong>bold</strong>).' | $0 -c config.cfg [-ds]
	-c 		config file
	-d 		debug
	-s 		disable SSL cert verification
EOF
	exit 1;
}

sub read_config{
	my $handle;
	my $config_name=pop;
	my $config = {};
	open $handle, "<:encoding(utf8)", $config_name;
	while (<$handle>) {
		chomp;                  # no newline
		s/#.*//;                # no comments
		s/^\s+//;               # no leading white
		s/\s+$//;               # no trailing white
		next unless length;     # anything left?
		#my ($var, $value) = split(/\s*=\s*/, $_, 2);
		/([^=\s]+)\s*=\s*([^#]+)(\s*|#).*/;
		my ($var, $value) = ($1, $2);
		$config->{$var} = $value;
	}
	close $handle;
	return $config;
}

sub main{	
	# build URL
	$config->{url} = join '', $config->{server_url},
		'/_matrix/client/r0/rooms/',
		$config->{room},
		'/send/m.room.message?access_token=',
		$config->{access_token};
	
	# create new LWC object
	my $browser = LWP::UserAgent->new;
	$browser = LWP::UserAgent->new(ssl_opts => { SSL_verify_mode => 0x00 })
		if $opts->{s};
	
	my $data = {
		"msgtype" =>  "m.text",
		"format" => "org.matrix.custom.html",
		"formatted_body" => $message,
		"body" => $message
	};
	
	# encode data to JSON and send post request
	my $response = $browser->post( $config->{url}, [], Content => encode_json($data) );
	
	# error reporting
	die "Error: ",$response->content unless $response->is_success;
	if ($opts->{d}) {
		print 'Content type is ', $response->content_type, $/;
		print 'Content is:', $response->content, $/;
	}
	return 0;
}
