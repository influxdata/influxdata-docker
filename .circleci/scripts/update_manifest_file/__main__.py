from debian.deb822 import Deb822
from debian.deb822 import Deb822Dict
import argparse
import os
import re
import sys


def reg_major(major: int) -> str:
    """
    reg_major

    Generates a partial-regular expression that matches the
    supplied `major` version.
    """
    # This forces `major` to be an integer by using the integer format
    # specifier. This sanitization is important so that regex cannot
    # be accidentally inserted into `re.sub`. If `major` is not an
    # integer, this aborts the program.
    return r"(" + "{0:d}".format(major) + r")"


def reg_minor(minor: int) -> str:
    """
    reg_minor

    Generates a partial-regular expression that matches the
    supplied `minor` version.
    """
    # This forces `minor` to be an integer by using the integer format
    # specifier. This sanitization is important so that regex cannot
    # be accidentally inserted into `re.sub`. If `minor` is not an
    # integer, this aborts the program.
    return r"(?:\.(" + "{0:d}".format(minor) + r"))"


def reg_patch() -> str:
    """
    reg_patch

    Generates a partial-regular expression that matches any patch
    version.
    """
    return r"(?:\.(\d+))"


def paragraph_cb(index, paragraph):
    """
    paragraph_cb
    """

    def paragraph_repo_cb(paragraph):
        # This callback is executed for the 'repository' paragraph. This
        # is currently defined as the first paragraph. This paragraph
        # usually has the keys 'Maintainers', 'GitRepo', and
        # 'GitCommit'.

        def item_cb(key, value):
            if key == "GitCommit":
                return os.environ.get("CIRCLE_SHA1")
            else:
                return value

        return {k: item_cb(k, v) for (k, v) in paragraph.items()}

    def paragraph_rele_cb(paragraph):
        # This callback is executed for every 'release' paragraph. This
        # is currently defined as every paragraph following the first.
        # This paragraph usually has the keys 'Tags', 'Architectures',
        # and 'Directory'.

        def item_cb(key, value):
            # If this has encountered a 'Tags:' key-value pair, update all
            # matching 'Major.Minor.Patch' versions. `major` and `minor`
            # must match `VERSION_MAJOR` and `VERSION_MINOR`. `patch`
            # can be any integer.
            if key == "Tags":
                # fmt: off
                return re.sub(
                    reg_major(int(os.environ.get("VERSION_MAJOR"))) +
                    reg_minor(int(os.environ.get("VERSION_MINOR"))) +
                    reg_patch(),
                    os.environ.get("VERSION"),
                    value,
                )
                # fmt: on
            else:
                return value

        return {k: item_cb(k, v) for (k, v) in paragraph.items()}

    # fmt: off
    return (
        paragraph_repo_cb(paragraph) if index == 0 else
        paragraph_rele_cb(paragraph)
    )
    # fmt: on

with open(sys.argv[1], "rb") as content:
    # fmt: off
    document = [
        paragraph_cb(index, parser) for index, parser in
            enumerate(Deb822.iter_paragraphs(content))
    ]
    # fmt: on

with open(sys.argv[1], "w") as output:
    for paragraph in document:
        # The `Deb822` constructor requires a `Sequence`-like object. Since
        # each `paragraph` within the `document` is a `Dict` (which does
        # not implement the `Sequence` methods), this constructs a
        # `Deb822dict` instance as an intermediate.
        output.write("{0:s}\n".format(Deb822(Deb822Dict(paragraph)).dump()))
