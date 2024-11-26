vcl 4.1;

backend default {
    .host = "host.docker.internal";
    .port = "9080";
}

sub vcl_recv {
    # Remove any existing ESI related headers
    unset req.http.Surrogate-Capability;
}

sub vcl_backend_response {
    # Enable ESI processing
    set beresp.do_esi = true;

    # Set caching headers
    if (beresp.status == 200) {
        unset beresp.http.Set-Cookie;
    }
}

sub vcl_deliver {
    # Remove ESI headers from client response
    unset resp.http.Surrogate-Control;
}