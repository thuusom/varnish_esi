
# Varnish ESI with JSON Example

This project demonstrates an attempt to use Varnish's Edge Side Includes (ESI) to assemble a JSON response from cached fragments. It includes scripts to set up Varnish and Nginx in Docker containers.

**Note:** Varnish's ESI functionality is designed for XML/HTML content and may not work as expected with JSON due to parsing limitations. This example highlights these challenges and suggests alternative approaches.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Setup Instructions](#setup-instructions)
- [Testing the Setup](#testing-the-setup)
- [Understanding the Issues](#understanding-the-issues)
- [Alternative Approaches](#alternative-approaches)
- [Cleanup](#cleanup)
- [References](#references)

## Prerequisites

- Docker installed on your machine.
- Basic understanding of Docker, Nginx, and Varnish.
- Familiarity with JSON, ESI, and caching concepts.

## Project Structure

```
.
├── start_cache.sh
├── start_nginx.sh
├── nginx
│   ├── default.conf
│   └── html
│       ├── tvChannels.json
│       └── currentProgram
│           ├── channel1.json
│           └── channel2.json
└── varnish
    └── default.vcl
```

- **start_cache.sh**: Script to start Varnish.
- **start_nginx.sh**: Script to start Nginx.
- **nginx/**: Contains Nginx configuration and static content.
- **varnish/**: Contains Varnish configuration.

## Setup Instructions

### 1. Start Nginx

Run the `start_nginx.sh` script to start the Nginx container:

```bash
./start_nginx.sh
```

This script:

- Stops and removes any existing `nginx-server` container.
- Starts a new Nginx container with:
  - Port `9080` mapped to the host.
  - Static content served from `nginx/html`.
  - Nginx configuration loaded from `nginx/default.conf`.

### 2. Start Varnish

Run the `start_cache.sh` script to start the Varnish container:

```bash
./start_cache.sh
```

This script:

- Stops and removes any existing `varnish-appcache` container.
- Starts a new Varnish container with:
  - Port `9090` mapped to the host.
  - Varnish configuration loaded from `varnish/default.vcl`.
  - ESI processing enabled with `feature=+esi_disable_xml_check`.

### 3. Directory and File Details

#### nginx/default.conf

```nginx
server {
    listen 80;
    server_name localhost;

    root /usr/share/nginx/html;

    location / {
        try_files $uri $uri/ =404;
    }

    location = /tvChannels {
        default_type application/json;
        add_header Cache-Control "max-age=60";
        try_files /tvChannels.json =404;
    }

    location /tvChannel/currentProgram {
        default_type application/json;
        add_header Cache-Control "max-age=30";

        if ($arg_channelId = "") {
            return 404 '{"error":"Channel ID not provided"}';
        }

        try_files /currentProgram/channel$arg_channelId.json =404;
    }
}
```

#### nginx/html/tvChannels.json

```json
[
    {
        "id": 1,
        "name": "SVT1",
        "currentProgram": "<esi:include src=\"/tvChannel/currentProgram?channelId=1\"/>"
    },
    {
        "id": 2,
        "name": "SVT2",
        "currentProgram": "<esi:include src=\"/tvChannel/currentProgram?channelId=2\"/>"
    }
]
```

#### nginx/html/currentProgram/channel1.json

```json
{
    "id": 12345,
    "name": "News",
    "startTime": "1234567",
    "duration": 3600
}
```

#### nginx/html/currentProgram/channel2.json

```json
{
    "id": 54321,
    "name": "Movie",
    "startTime": "1234567",
    "duration": 3600
}
```

#### varnish/default.vcl

```vcl
vcl 4.1;

backend default {
    .host = "nginx-server";
    .port = "80";
}

sub vcl_recv {
    unset req.http.Surrogate-Capability;
}

sub vcl_backend_response {
    set beresp.do_esi = true;
    if (beresp.status == 200) {
        unset beresp.http.Set-Cookie;
    }
}

sub vcl_deliver {
    unset resp.http.Surrogate-Control;
}
```

## Testing the Setup

### 1. Access the Endpoint via Varnish

Make a request to the `/tvChannels` endpoint through Varnish:

```bash
curl -i http://localhost:9090/tvChannels?includeCurrentProgram=true
```

### 2. Expected Behavior

- **Expected Response**: The `currentProgram` fields should contain the included JSON content.

**However**, due to Varnish's ESI limitations with JSON, you may encounter issues where the `currentProgram` fields are empty or the ESI tags are not processed correctly.

### 3. Examine Varnish Logs

To debug, inspect the Varnish logs:

```bash
docker exec -it varnish-appcache varnishlog
```

Look for errors such as:

```
ESI_xmlerror   ERR after 76 XML 1.0 Missing end attribute delimiter
```

## Understanding the Issues

### ESI and JSON Compatibility

- **ESI Designed for XML/HTML**: Varnish's ESI parser expects the content to be valid XML or HTML.
- **JSON is Not XML**: Embedding ESI tags directly into JSON can lead to parsing errors, as JSON syntax is not compatible with XML parsing.

## Alternative Approaches

### 1. Assemble JSON on the Backend

Modify your backend application to include the `currentProgram` data when generating the `/tvChannels` response.

### 2. Use Separate Endpoints and Client-Side Logic

Serve the channel list without the `currentProgram` data and have clients request `currentProgram` data separately.

### 3. Implement Backend Fragment Caching

Use application-level caching to assemble the response from cached fragments.

## Cleanup

To stop and remove the Docker containers:

```bash
docker stop varnish-appcache nginx-server
docker container rm varnish-appcache nginx-server
```

## References

- [Varnish ESI Documentation](https://varnish-cache.org/docs/7.0/users-guide/esi.html)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Docker Documentation](https://docs.docker.com/)

---

**Note**: This example highlights the challenges of using Varnish ESI with JSON content. It's recommended to consider alternative caching strategies better suited for JSON APIs.
