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

get '/api/cubism_values' => sub {
    my ($c) = @_;

    my $start_timestamp = $c->param('start');
    my $stop_timestamp = $c->param('stop');
    my $step_seconds = $c->param('step');
    my $name = $c->param('name');

    my ($mac, $what) = split(/_/, $name);

    my %allowed = (
        t => 1,
        h => 1,
    );

    die 'incorrect name' if not $allowed{$what // ''};

    my $sth = get_dbh()->prepare("select timestamp, $what from dots where timestamp >= ? and timestamp <= ? and mac = ? order by timestamp");
    $sth->execute(
        $start_timestamp,
        $stop_timestamp,
        $mac,
    );

    my @db_values;

    while (my $row = $sth->fetch()) {
		push @db_values, {
            timestamp => $row->[0],
            value => $row->[1],
        };
	}

    my $val = 0;
    my $db_element = shift @db_values;

    my @values;
    for (my $cursor_timestamp = $start_timestamp; $cursor_timestamp <= $stop_timestamp; $cursor_timestamp += $step_seconds) {
        if (defined($db_element) && $db_element->{timestamp} >= $cursor_timestamp) {
            $val = $db_element->{value};
            $db_element = shift @db_values;
        }

        push @values, $val;
    }

    $c->render(
        json => \@values,
    );
};

if (!-e '/data_db/db.db') {
	create_db();
}

app->start;
