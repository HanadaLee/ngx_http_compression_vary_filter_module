#!/usr/bin/perl

# Tests for ngx_http_compression_vary_filter_module.

###############################################################################

use warnings;
use strict;

use Test::More;

BEGIN { use FindBin; chdir($FindBin::Bin); }

use Test::Nginx;

###############################################################################

select STDERR; $| = 1;
select STDOUT; $| = 1;

my $t = Test::Nginx->new()->has(qw/http gzip
	ngx_http_compression_vary_filter_module/)->plan(12);

$t->write_file_expand('nginx.conf', <<'EOF');

%%TEST_GLOBALS%%

daemon off;

events {
}

http {
    %%TEST_GLOBALS_HTTP%%

    server {
        listen       127.0.0.1:8080;
        server_name  localhost;

        default_type text/plain;
        gzip on;
        gzip_min_length 0;
        gzip_types text/plain;
        gzip_vary off;
        compression_vary on;

        location = /basic {
            return 200 basic-response;
        }

        location = /merge {
            add_header Vary "Origin, accept-encoding";
            add_header Vary "User-Agent, Origin";
            return 200 merge-response;
        }

        location = /existing {
            gzip off;
            add_header Vary "Origin, User-Agent";
            add_header Vary origin;
            return 200 existing-response;
        }

        location = /off {
            compression_vary off;
            return 200 off-response;
        }

        location = /plain {
            gzip off;
            return 200 plain-response;
        }
    }
}

EOF

$t->run();

###############################################################################

my $response = http_get('/basic');
like($response, qr/^HTTP\/1\.1 200 /, 'inherited setting serves response');
like($response, qr/^Vary: Accept-Encoding\x0d$/m,
	'compressible response varies without client gzip');

$response = request('/basic', 'gzip');
like($response, qr/^Vary: Accept-Encoding\x0d$/m,
	'gzip response varies by accept-encoding');
like($response, qr/^Content-Encoding: gzip\x0d$/m,
	'gzip response is compressed');
is(() = $response =~ /^Vary:/mg, 1, 'basic response has one vary field');

$response = http_get('/merge');
like($response,
	qr/^Vary: Origin, accept-encoding, User-Agent\x0d$/m,
	'multiple vary fields are merged and deduplicated');
is(() = $response =~ /^Vary:/mg, 1, 'merged response has one vary field');

$response = http_get('/existing');
like($response, qr/^Vary: Origin, User-Agent\x0d$/m,
	'existing values are deduplicated without compression');
unlike($response, qr/^Vary:.*Accept-Encoding/m,
	'accept-encoding is not added when compression is inactive');
is(() = $response =~ /^Vary:/mg, 1, 'existing response has one vary field');

unlike(http_get('/off'), qr/^Vary:/m,
	'off overrides inherited compression vary');
unlike(http_get('/plain'), qr/^Vary:/m,
	'plain response without vary stays unchanged');

###############################################################################

sub request {
	my ($uri, $accept_encoding) = @_;

	return http(<<EOF);
GET $uri HTTP/1.1
Host: localhost
Accept-Encoding: $accept_encoding
Connection: close

EOF
}

###############################################################################
