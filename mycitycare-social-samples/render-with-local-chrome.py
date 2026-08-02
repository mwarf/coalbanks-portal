#!/usr/bin/env python3
"""Run the MyCityCare renderers with Chrome's sandbox disabled in this workspace."""

import os
import runpy
import subprocess
import sys


real_run = subprocess.run


def compatible_run(args, *pargs, **kwargs):
    if isinstance(args, list) and args and "Google Chrome" in args[0]:
        args = [args[0], "--no-sandbox", "--headless=new", *args[1:]]
    return real_run(args, *pargs, **kwargs)


if len(sys.argv) < 2:
    raise SystemExit("Usage: render-with-local-chrome.py RENDERER [ARGS ...]")

renderer = os.path.abspath(sys.argv[1])
sys.argv = [renderer, *sys.argv[2:]]
subprocess.run = compatible_run
runpy.run_path(renderer, run_name="__main__")
