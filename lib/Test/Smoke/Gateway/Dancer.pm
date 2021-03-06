package Test::Smoke::Gateway::Dancer;
use v5.10;
no if $] >= 5.018, warnings => 'experimental::smartmatch';

use Dancer ':syntax';

use Dancer::Plugin::DBIC;
use Encode 'encode';
use Test::Smoke::Gateway;
use Try::Tiny;

no if $] >= 5.018, warnings => 'experimental::smartmatch';

my $gw = Test::Smoke::Gateway->new(schema => schema());

post '/report' => sub {
    try {
        my $json = encode('utf-8', params->{json});
        my $data = from_json($json);
        my $report = $gw->post_report($data);
        debug("Report was posted, returning id = ", $report->id);
        return to_json({id => $report->id});
    }
    catch {
        when (/duplicate key/) {
            debug("Report is a duplicate: $_");
            return to_json(
                {
                    error    => 'Report already posted.',
                    db_error => "$_",
                }
            );
        }
        default {
            debug("Report could not be stored in the database: $_");
            return to_json(
                {
                    error    => 'Unexpected error.',
                    db_error => "$_"
                }
            );
        }
    };
};

get '/report/:id' => sub {
    my $report = $gw->get_report(params->{'id'});

    header 'content-type' => 'text/html';
    template 'report' => {
        report   => $report,
        title    => $report->title,
        version  => $Test::Smoke::Gateway::VERSION,
        thisyear => 1900 + (localtime)[5],
    };
};

get '/logfile/:id' => sub {
    my $report = $gw->get_report(params->{'id'});

    header 'content-type' => 'text/html';
    template 'logfile' => {
        report   => $report,
        title    => $report->title,
        version  => $Test::Smoke::Gateway::VERSION,
        thisyear => 1900 + (localtime)[5],
    };
};

get '/outfile/:id' => sub {
    my $report = $gw->get_report(params->{'id'});

    header 'content-type' => 'text/html';
    template 'outfile' => {
        report   => $report,
        title    => $report->title,
        version  => $Test::Smoke::Gateway::VERSION,
        thisyear => 1900 + (localtime)[5],
    };
};

post '/search' => sub {
    header 'content-type' => 'text/html';
    template 'search' => {
        search   => $gw->search({params}),
        title    => 'Test::Smoke Database Search',
        version  => $Test::Smoke::Gateway::VERSION,
        thisyear => 1900 + (localtime)[5],
    };
};

get '/search' => sub {
    header 'content-type' => 'text/html';
    template 'search' => {
        search   => $gw->search({params}),
        title    => 'Test::Smoke Database Search',
        version  => $Test::Smoke::Gateway::VERSION,
        thisyear => 1900 + (localtime)[5],
    };
};

get '/test' => sub {
    header 'content-type' => 'text/html';
    template 'test' => {
        title    => 'Test::Smoke Database TEST Page',
        version  => $Test::Smoke::Gateway::VERSION,
        thisyear => 1900 + (localtime)[5],
    };
};

get '/api/reports_from_date/:epoch' => sub {
    return to_json($gw->api_get_reports_from_date(params->{epoch}));
};

get '/api/reports_from_id/:id' => sub {
    my @args = (params->{id});
    push @args, params->{limit} // 100;
    return to_json($gw->api_get_reports_from_id(@args));
};

get '/api/report_data/:id' => sub {
    return to_json($gw->api_get_report_data(params->{id}));
};

get '/' => sub {
    forward '/search';
};

1;
