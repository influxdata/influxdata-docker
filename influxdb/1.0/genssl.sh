#!/bin/bash

set -e

openssl req -x509 -batch -newkey rsa:2048 -keyout key.pem -out cert.pem -days 0 -nodes
cat key.pem cert.pem > influxdb.pem
cp influxdb.pem alpine/influxdb.pem
rm -f key.pem cert.pem
