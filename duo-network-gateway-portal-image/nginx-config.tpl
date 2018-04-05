server {{
    listen {external_port};
    server_name {external_host};

    ssl                  on;
    ssl_certificate      {cert_file};
    ssl_certificate_key  {key_file};

    access_log  stderr aperture_log_fmt;
    error_log   stderr notice;

    # add STS header with a large expiration (year)
    add_header Strict-Transport-Security max-age=31536000;

    # require beyond corp authentication
    auth_request /_verify;

    # Get the logged-in user
    auth_request_set $aperture_username $upstream_http_x_aperture_username;

    # redirect to the global session check if beyondserv says service session is not valid
    auth_request_set $beyondcorp_check $upstream_http_x_beyondcorp_check;
    error_page 401 $beyondcorp_check;

    location = /_verify {{
        internal;
        auth_request off;

        proxy_pass http://aperture_load_balance_group;
        proxy_buffering off;
        proxy_pass_request_body off;
        proxy_set_header Content-Length "";
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Real-Port {external_port};
        proxy_set_header X-Original-URI $request_uri;
        proxy_set_header X-Request-ID $request_id;
    }}

    location = /_set {{
        # user won't have an access cookie yet, so don't require auth
        auth_request off;

        proxy_pass http://unix:@aperture-main;
        proxy_buffering off;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Request-ID $request_id;
    }}

    {whitelist_prefixes}
    {whitelist_suffixes}
    {arc_config}

    location / {{
        set $aperture_username '';

        resolver kube-dns.kube-system.svc.cluster.local; # Updated from weird hard-coded IP
        set $upstream {internal_proto}://{internal_host}:{internal_port};
        proxy_pass $upstream;
        proxy_buffering off;
        proxy_set_header Host {upstream_host_header};
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;

        proxy_ssl_verify {internal_ssl};
        proxy_ssl_name {internal_sni_host};
        proxy_ssl_server_name on;
        proxy_ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        proxy_ssl_trusted_certificate {icert_file};
        proxy_ssl_verify_depth 9;
    }}
}}
