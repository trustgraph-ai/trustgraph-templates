#!/usr/bin/env python3

import _jsonnet as j
import json
import os
import logging

import zipfile
import pathlib
from io import BytesIO
import argparse

logger = logging.getLogger("generator")
logger.setLevel(logging.INFO)

private_json = "Put your GCP private.json here"

class Generator:

    def __init__(
        self, config, templates="./templates/", resources="./resources",
        version="0.0.0",
    ):

        self.templates = pathlib.Path(templates)
        self.resources = pathlib.Path(resources)
        self.config = config
        self.version = f"\"{version}\"".encode("utf-8")

    def process(self, config):

        res = j.evaluate_snippet("config", config, import_callback=self.load)
        return json.loads(res)

    def load(self, dir, filename):

        logger.debug("Request jsonnet: %s %s", dir, filename)

        values_dir = self.templates.joinpath("values")

        if filename == "config.json" and dir == "":
            path = os.path.join(".", dir, filename)
            return str(path), self.config

        if filename == "version.jsonnet":
            if pathlib.Path(dir) == values_dir:
                path = os.path.join(".", dir, filename)
                return str(path), self.version

        if dir:
            candidates = [
                self.templates.joinpath(dir, filename),
                self.templates.joinpath(filename),
                self.resources.joinpath(dir, filename),
                self.resources.joinpath(filename),
                pathlib.Path(dir).joinpath(filename),
            ]
        else:
            candidates = [
                self.templates.joinpath(filename),
                pathlib.Path(dir).joinpath(filename),
                pathlib.Path(filename),
            ]

        try:

            if filename == "vertexai/private.json":

                return str(candidates[0]), private_json.encode("utf-8")

            for c in candidates:
                logger.debug("Try: %s", c)

                if os.path.isfile(c):
                    with open(c, "rb") as f:
                        logger.debug("Loading: %s", c)
                        return str(c), f.read()

            raise RuntimeError(
                f"Could not load file={filename} dir={dir}"
            )
                
        except:

            path = os.path.join(self.templates, filename)
            logger.debug("Try: %s", path)
            with open(path, "rb") as f:
                logger.debug("Loaded: %s", path)
                return str(path), f.read()

