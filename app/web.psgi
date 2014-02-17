use strict;
use warnings;
use lib '/home/hunter/dev/mojomojo/lib';
use MojoMojo;
use lib '/home/hunter/dev/Bracket/lib';
use Bracket;
use lib '/home/hunter/dev/HomePage/lib';
use HomePage;
use lib '/home/hunter/dev/Mojito/lib';
use lib '/home/hunter/dev/RankBall/lib';
use Plack::Builder;
use Plack::Util;
use Plack::App::File;
use Plack::App::Cascade;
use File::Slurp;

MojoMojo->setup_engine('PSGI');
my $mojomojo_app = sub { MojoMojo->run(@_) };
Bracket->setup_engine('PSGI');
my $bracket_app  = sub { Bracket->run(@_) };
HomePage->setup_engine('PSGI');
my $homepage_app = sub { HomePage->run(@_) };

my $mojito_app = Plack::Util::load_psgi '/home/hunter/dev/Mojito/app.psgi';
my $rank_ball_app = Plack::Util::load_psgi '/home/hunter/dev/RankBall/app.psgi';
my $home_page = "/home/hunter/www/index.html";
my $root_app = sub { [200, ['Content-type', 'text/html'],[read_file($home_page)]] };
my $static_app = Plack::App::File->new(root => "/home/hunter/www")->to_app;
my $cascaded_root_app = Plack::App::Cascade->new(apps => [$static_app, $root_app ])->to_app;

use CGI::Emulate::PSGI;
use CGI::Compile;
my $cgi_script = "/home/hunter/cgi-bin/secure/contacts.cgi";
my $sub = CGI::Compile->compile($cgi_script);
my $contacts_app = CGI::Emulate::PSGI->handler($sub);

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
    mount "/cgi-bin/contacts.cgi" => builder {
        enable "Auth::Htpasswd", file => '/home/hunter/passwords/.htpasswd';
        $contacts_app;
    };
    mount "/rank"    => $rank_ball_app;
    mount "/"        => $cascaded_root_app;
};
