#!/usr/bin/env python3
# -*- mode: python -**

import fileinput, os

dests = dict()
"""A dictionary associating absolute file names and file objects."""

counter = dict()
"""A dictionary associating file objects with count of emitted
lines."""

dest = None
"""The current "destination", a file object"""

buf = list()
"""Buffered lines from the current code block.  Buffering is required
because we need to drop leading spaces before writing to the file, and
full contents is required to determine the number of spaces to remove.
"""

def match_begin(line):
    """Read a single line and return a file object if it's a #+begin_src, None otherwise.

Also create corresponding entries in dests and counter if they don't already exist."""
    line = list(filter(
        len,
        line.lower().strip().split(" ")))

    if line and line[0] == "#+begin_src":
        try:
            beg = line.index(":tangle")
        except ValueError:
            return False

        dest = os.path.realpath(os.path.expanduser(line[beg+1]))
        if not dest in dests.keys():
            fo = open(dest, 'w')
            dests[dest] = fo
            counter[fo] = 0
        else:
            fo = dests[dest]
            # Org mode does this
            fo.write("\n")
            counter[fo] += 1

        return fo

def match_end(line):
    """Return True if line is a #+end_src"""
    return line.lower().strip().startswith("#+end_src")

def write_buffer(dest, buf):
    """Drop extra leading spaces from buf, then write to dest."""
    # First, count how many spaces on the left we must remove.
    min = 1000
    for line in buf:
        ls = len(line.lstrip()) # Left strip
        if ls: # Ignore empty lines
            spaces = len(line) - ls
            if spaces < min:
                min = spaces

    # Then write the buffer to the file, dropping the extra indent
    for line in buf:
        counter[dest] += 1
        # If the line is empty, dropping the leading space will drop
        # the terminal \n, and will suppress blank lines.  We don't
        # want this._
        dest.write(line[min:-1])
        dest.write('\n')

for line in fileinput.input():
    if dest:
        if match_end(line):
            write_buffer(dest, buf)
            buf = list()
            dest = None
        else:
            buf.append(line)
    else:
        dest = match_begin(line)

for fn, fo in dests.items():
    fo.close()
    fn = os.path.relpath(fn, ".")
    c = str(counter[fo])
    print("{0} {1} {2} lines".format(
        fn,
        "." * (70 - len(fn) - len(c)),
        c))
