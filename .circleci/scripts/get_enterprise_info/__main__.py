#!/usr/bin/python3
from typing import Dict
from typing import Generator
from typing import Optional
import os
import re
import subprocess
import enum


def getenv(variable: str) -> str:
    """
    Retrieves `variable` from the environment.
    """
    # `os.getenv` returns `Dict[str]` which is incompatible with functions
    # that require `str` parameters. If `os.getenv` returns a value, it is
    # unwrapped and returned to the caller.
    value = os.getenv(variable)
    if value is not None:
        return value

    raise RuntimeError('Missing environment variable "{}".'.format(variable))


class GitDiff(enum.Enum):
    # fmt: off
    ADDED   = "\+"
    REMOVED = "\-"
    # fmt: on

    def __str__(self):
        return str(self.value)


def parse_env_line(line: str, diff: GitDiff) -> Optional[Dict[str, str]]:
    """
    Matches version line in dockerfile.
    """
    # fmt: off
    matches = re.match(
      r"^" + str(diff)             +  # changed?
      r"ENV\s+INFLUXDB_VERSION\s+" +  # prelude
       r"((\d+)"                   +  # major         cg: 2
       r"(?:\.(\d+))?"             +  # minor?        cg: 3
       r"(?:\.(\d+))?"             +  # patch?        cg: 4
       r"(?:\-?(rc\d+))?)"         +  # rc?           cg: 5
      r"-c"                        +  # interlude
      r"(\d+)"                     +  # repeat major  cg: 6
      r"(?:\.(\d+))?"              +  # repeat minor? cg: 7
      r"(?:\.(\d+))?"              +  # repeat patch? cg: 8
      r"(?:\-?(rc\d+))?",             # repeat rc?    cg: 9
      line)

    if matches is not None:
        # I tried using capture-group back-references within the regular
        # expression. However, it couldn't handle optional capture-
        # groups. So, instead, we check for equality here.
        if (matches.group(2) == matches.group(6) and
            matches.group(3) == matches.group(7) and
            matches.group(4) == matches.group(8) and
            matches.group(5) == matches.group(9)):
            return {
                "VERSION":       matches.group(1),
                "VERSION_MAJOR": matches.group(2),
                "VERSION_MINOR": matches.group(3) if matches.group(3) else "",
                "VERSION_PATCH": matches.group(4) if matches.group(4) else "",
                "VERSION_RC":    matches.group(5) if matches.group(5) else "",
            }
    return None
    # fmt: on


def parse_version() -> Optional[str]:
    """
    Parse version from "ENV" line in git.
    """
    # Retrieve all lines that have changed since the commit between
    # HEAD~1 and HEAD. This is more robust than just parsing the
    # current Dockerfile as it ensures that `INFLUXDB_VERSION`
    # actually changed.
    # fmt: off
    process = subprocess.run(
        ["git", "diff", "--unified=0", "HEAD~1..HEAD", "influxdb" ],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    # fmt: on

    version_prev = None
    version_curr = None
    for line in process.stdout.decode("utf-8").split("\n"):
        line = line.rstrip(" \t")
        prev = parse_env_line(line, GitDiff.REMOVED)
        curr = parse_env_line(line, GitDiff.ADDED)

        if prev is not None:
            version_prev = prev
        if curr is not None:
            version_curr = curr

        # fmt: off
        if (version_prev is not None and
            version_curr is not None):
            # if the versions differ, then this must be a release
            if version_prev["VERSION"] != version_curr["VERSION"]:
                return version_curr
        # fmt: on

        # If the `INFLUXDB_VERSION` line has changed but the version has
        # not changed, reset so the next encounter of `version_prev`
        # does not cause this to return the incorrect `version_curr`.
        if version_curr != None:
            version_prev = None
            version_curr = None

    # no version change in dockerfile
    return None


version = parse_version()
if version is not None:
    with open(getenv("BASH_ENV"), "a") as stream:
        stream.write("export PRODUCT=influxdb\n")
        for key, value in version.items():
            stream.write("export {}={}\n".format(key, value))
