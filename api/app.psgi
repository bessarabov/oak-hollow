use utf8;

use strict;
use warnings FATAL => 'all';

use DBI;
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

sub get_dbh {

   my $dbh = DBI->connect(
       "dbi:SQLite:dbname=/data_db/db.db",
       '',
       '',
       {
           RaiseError     => 1,
           sqlite_unicode => 1,
       },
   );

   return $dbh;
}

sub create_db {
	my @sqls = (
		'CREATE TABLE dots(timestamp INTEGER, mac TEXT, t REAL, h REAL);',
	);

    my $dbh = get_dbh();

    my $sth;

    foreach my $sql (@sqls) {
        $sth = $dbh->prepare($sql);
        $sth->execute();
    }
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

    my $sth = get_dbh()->prepare(
        'insert into dots (timestamp, mac, t, h) values (?, ?, ?, ?)',
    );

	$sth->execute(
		$parsed_body->{timestamp},
		$parsed_body->{mac},
		$parsed_body->{t},
		$parsed_body->{h},
	);

    $c->render(
        json => {
        },
    );
};

get '/api/macs' => sub {
    my ($c) = @_;

	my @macs;

    my $sth = get_dbh()->prepare('select distinct mac from dots order by mac');
    $sth->execute();

    while (my $row = $sth->fetch()) {
		push @macs, $row->[0];
	}

    $c->render(
        json => \@macs,
    );
};

if (!-e '/data_db/db.db') {
	create_db();
}

app->start;
