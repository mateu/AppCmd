use strict;
use warnings;
use lib '/home/hunter/dev/mojomojo/lib';
use MojoMojo;
use lib '/home/hunter/dev/Bracket/lib';
use Bracket;
use lib '/home/hunter/dev/HomePage/lib';
use HomePage;
use lib '/home/hunter/dev/Mojito/lib';
use Plack::Builder;
use Plack::Util;

MojoMojo->setup_engine('PSGI');
my $mojomojo_app = sub { MojoMojo->run(@_) };

Bracket->setup_engine('PSGI');
my $bracket_app = sub { Bracket->run(@_) };

HomePage->setup_engine('PSGI');
my $homepage_app = sub { HomePage->run(@_) };

my $mojito_app = Plack::Util::load_psgi '/home/hunter/dev/Mojito/app/mojito.pl';

builder {
    mount "/wiki"    => builder {
        enable_if { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' }
          "Plack::Middleware::ReverseProxy";
        $mojomojo_app;
    };
    mount "/bracket" => builder {
        enable_if { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' }
          "Plack::Middleware::ReverseProxy";
        $bracket_app;
    };
    mount "/mi"      => $homepage_app;
    mount "/note"    => $mojito_app;
};
