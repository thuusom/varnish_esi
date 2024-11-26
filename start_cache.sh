#!/bin/bash
docker stop varnish-appcache
docker container rm varnish-appcache

docker run --name varnish-appcache \
  -p 9090:80 \
  -v $(pwd)/varnish/default.vcl:/etc/varnish/default.vcl:ro \
  -d varnish:latest \
  varnishd \
    -F \
    -f /etc/varnish/default.vcl \
    -a :80 \
    -s malloc,256m \
    -p feature=+esi_disable_xml_check
