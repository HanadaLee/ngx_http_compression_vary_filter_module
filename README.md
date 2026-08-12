# ngx_http_compression_vary_filter_module

# Name
ngx_http_compression_vary_filter_module is a header filter module used instead of the `gzip_vary` directive.

# Table of Content

- [ngx\_http\_compression\_vary\_filter\_module](#ngx_http_compression_vary_filter_module)
- [Name](#name)
- [Table of Content](#table-of-content)
- [Status](#status)
- [Synopsis](#synopsis)
- [Installation](#installation)
- [Directives](#directives)
  - [compression\_vary](#compression_vary)
- [Author](#author)
- [License](#license)

# Status

This Nginx module is currently considered experimental. Issues and PRs are welcome if you encounter any problems.

# Synopsis

```nginx
server {
    listen 127.0.0.1:8080;
    server_name localhost;

    location / {
        gzip on;
        gzip_vary off;           # Disable gzip_vary to avoid conflicts with compression_vary
        compression_vary on;

        proxy_pass http://foo.com;
    }
}
```

# Installation

To use theses modules, configure your nginx branch with `--add-module=/path/to/ngx_http_compression_vary_filter_module`.

# Directives

## compression_vary

**Syntax:** *compression_vary on | off;*

**Default:** *compression_vary off;*

**Context:** *http, server, location*

Enables or disables inserting the `Vary: Accept-Encoding` response header field if the directives `gzip`, `gzip_static`, or `gunzip` are active.

Unlike `gzip_vary`, if a `Vary` header exists for the original response, it will append the `Accept-Encoding` to the original `Vary` header. In addition, multiple `Vary` headers will be merged into one and separated by commas. Duplicate header values ​​in `Vary` will be removed.

Note that `compression_vary` should not be used simultaneously with `gzip_vary`, as this will result in duplicate `Vary` headers.

This module is also effective when the directives from third-party compression modules such as `brotli`, `brotli_static`, `unbrotli`, `zstd`, `zstd_static`, `unzstd` and `undeflate` are activated.

# Author

Hanada im@hanada.info

# License

This Nginx module is licensed under [BSD 2-Clause License](LICENSE).
