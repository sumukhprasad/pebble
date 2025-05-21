package Pebble::Server;

use strict;
use warnings;
use HTTP::Server::Simple::CGI;
use base qw(HTTP::Server::Simple::CGI);
use File::Spec;
use IO::Socket::INET;
use AnyEvent;
use AnyEvent::WebSocket::Server;
use File::ChangeNotify;
use File::Slurp;


use Pebble::Builder;

my @clients;

sub handle_request {
	my ($self, $cgi) = @_;
	my $path = $cgi->path_info() || '/index.html';
	$path =~ s/\.\.//g;
	my $site_dir = $self->{site_dir};
	$path = File::Spec->catfile($site_dir, $path);

	if (-d $path) {
		$path = File::Spec->catfile($path, 'index.html');
	}

	if (-e $path) {
		open my $fh, '<', $path;
		binmode $fh;
		print "HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n";
		my $content = do { local $/; <$fh> };

		my $reload_script = "<script>const ws = new WebSocket('ws://localhost:5678');ws.onmessage = () => location.reload();</script>";

		$content =~ s{</body>}{$reload_script . '</body>'}e;

		print $content;
	} else {
		print "HTTP/1.0 404 Not Found\r\nContent-Type: text/plain\r\n\r\nNot Found";
	}
}

sub start_server {
	my ($class, $port, $site_dir, $output_dir) = @_;
	$port ||= 3000;

	print "Pebble serving on http://localhost:$port\n";

	my $server = $class->new($port);
	my $pid = fork();
	
	$server->{site_dir} = $output_dir;
	
	if ($pid == 0) {
		$server->run();
		exit;
	}

	my $ws_server = AnyEvent::WebSocket::Server->new;
	my $tcp = IO::Socket::INET->new(LocalPort => 5678, Listen => 5, Reuse => 1)
		or die "Can't open websocket.";

	my $ae = AnyEvent->io(
		fh   => $tcp,
		poll => 'r',
		cb   => sub {
			my $client = $tcp->accept;
			$ws_server->establish($client)->cb(sub {
				my $conn = shift->recv;
				push @clients, $conn;
				$conn->on_finish(sub {
					@clients = grep { $_ != $conn } @clients;
				});
			});
		}
	);

	my $watcher = File::ChangeNotify->instantiate_watcher(
		directories => [$site_dir], 
		filter	  => qr/\.(md|html|scss|css|js|yml|pl|sass)$/,
		recurse	 => 1,
	);

	my $cv = AnyEvent->condvar;

	my $is_rebuilding = 0;

	my $watch = AnyEvent->timer(
		after	 => 1,
		interval   => 1,
		cb	      => sub {
			return if $is_rebuilding;

			my @events = $watcher->new_events;

			if (@events) {
				$is_rebuilding = 1;
				
				print "Change detected, rebuilding...\n";
				print "Changed: ", $_->path, "\n" for @events;
				
				undef $watcher;

				Pebble::Builder::build($site_dir, $output_dir);

				$_->send("reload") for @clients;
				
				$watcher = File::ChangeNotify->instantiate_watcher(
					directories => [$site_dir], 
					filter      => qr/\.(md|html|scss|css|js|yml|pl|sass)$/,
					recurse     => 1,
				);

				$is_rebuilding = 0;

				$is_rebuilding = 0;
			}
		}
	);

	$cv->recv;
}

1;