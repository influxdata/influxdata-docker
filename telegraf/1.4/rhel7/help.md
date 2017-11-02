% TELEGRAF (1) Container Image Pages
% Gunnar Aasen
% July 31, 2017

# NAME
telegraf \- telegraf container image

# DESCRIPTION
Telegraf is an open source agent written in Go for collecting metrics and data on the system it's running on or from other services. Telegraf writes data it collects to InfluxDB in the correct format.

Files added to the container during docker build include: /help.1.

# USAGE

The default configuration requires a running InfluxDB instance as an output plugin. Ensure that InfluxDB is running on port 8086 before starting the Telegraf container.

Minimal example to start an InfluxDB container:

```console
$ docker run -d --name influxdb -p 8083:8083 -p 8086:8086 influxdb
```

Starting Telegraf using the default config, which connects to InfluxDB at `http://localhost:8086/`:

```console
$ docker run --net=container:influxdb telegraf
```

# LABELS

# SECURITY IMPLICATIONS

Telegraf exposes the following ports by default

-	8125 StatsD
-	8092 UDP
-	8094 TCP

# HISTORY
Similar to a Changelog of sorts which can be as detailed as the maintainer wishes.

# AUTHORS
Gunnar Aasen