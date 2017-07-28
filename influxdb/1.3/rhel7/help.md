% INFLUXDB (1) Container Image Pages
% Gunnar Aasen
% June 12, 2017

# NAME
influxdb \- influxdb container image

# DESCRIPTION
The InfluxDB image provides an example of how a RHEL-based image build could start.

The starter-scratch image is designed to be run by the atomic command with one of these options:

`run`

Starts the installed container with selected privileges to the host.

`stop`

Stops the installed container

`uninstall`

Removes the installed container, not the image

The container itself consists of:
    - RHEL7 base image
    - Atomic help file

Files added to the container during docker build include: /help.1.

# USAGE
To use the starter-scratch container, you can run the atomic command with run, stop, or uninstall options:

To run the starter-scratch container:

  atomic run acme/starter-scratch

To stop the starter-scratch container (after it is installed), run:

  atomic stop acme/starter-scratch

To remove the starter-scratch container (not the image) from your system, run:

  atomic uninstall acme/starter-scratch

# LABELS
The starter-scratch container includes the following LABEL settings:

That atomic command runs the docker command set in this label:

`RUN=`

  LABEL RUN='docker run -tdi --name ${NAME} ${IMAGE}'

  The contents of the RUN label tells an `atomic run acme/starter-scratch` command to open ports 8080/8443 & set the name of the container.

`Name=`

The registry location and name of the image. For example, Name="acme/starter-scratch".

`Version=`

The Red Hat Enterprise Linux version from which the container was built. For example, Version="7.2".

`Release=`

The specific release number of the container. For example, Release="12.1.a":

When the atomic command runs the starter-scratch container, it reads the command line associated with the selected option
from a LABEL set within the Docker container itself. It then runs that command. The following sections detail
each option and associated LABEL:

# SECURITY IMPLICATIONS
`THESE IMPLICATIONS DO NOT APPLY TO THIS IMAGE - this is only an example of what documentation might look like:`

Below is an example of what is referred to as a super-privileged container. It is designed to have almost complete
access to the host system as root user. The following docker command options open selected privileges to the host:

`-d`

Runs continuously as a daemon process in the background

`--privileged`

Turns off security separation, so a process running as root in the container would have the same access to the
host as it would if it were run directly on the host.

`--net=host`

Allows processes run inside the container to directly access host network interfaces

`--pid=host`

Allows processes run inside the container to see and work with all processes in the host process table

`--restart=always`

If the container should fail or otherwise stop, it would be restarted

# HISTORY
Similar to a Changelog of sorts which can be as detailed as the maintainer wishes.

# AUTHORS
Gunnar Aasen