use utf8;

use strict;
use warnings FATAL => 'all';

use Moment;
use JSON::PP;
use Path::Tiny;
use File::Basename;
use Mojolicious::Lite;

sub to_oneline_json {
	my ($data) = @_;

	my $json_coder = JSON::PP
		->new
		->canonical
		;

	my $json = $json_coder->encode($data);

	return $json;
}

get '/api/alive' => sub {
    my ($c) = @_;

    $c->render(
        json => {
        },
    );
};

post '/api/dot' => sub {
    my ($c) = @_;

	my $parsed_body = decode_json $c->req->body;

    my $now = Moment->now();

    $parsed_body->{timestamp} = $now->get_timestamp();

    # /data/2019/2019-09-27/4C:11:AE:0D:7E:FE.jsonl
    my $file_name = sprintf(
        '/data/%s/%s/%s.jsonl',
        $now->get_year(),
        $now->get_d(),
        $parsed_body->{mac},
    );

    my $dir = dirname($file_name);

    `mkdir -p $dir` if !-d $dir;

    path($file_name)->append(
        to_oneline_json($parsed_body) . "\n",
    );

    $c->render(
        json => {
        },
    );
};

app->start;
