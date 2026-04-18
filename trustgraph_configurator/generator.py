"""
Jsonnet snippet evaluator.

Wraps the gojsonnet native bindings to evaluate a Jsonnet template
(either a string snippet or a file) and return the rendered JSON as
a Python object. Import resolution is delegated to a fetch callback
supplied by the caller (typically Packager), which lets templates
reference bundled resources and dynamically-injected files such as
config.json and version.jsonnet.
"""

import _gojsonnet as j
import json
import os
import pathlib
import logging

logger = logging.getLogger("generator")
logger.setLevel(logging.INFO)

class Generator:

    def __init__(self, fetch):
        self.fetch = fetch

    def process(self, config):
        res = j.evaluate_snippet("config", config, import_callback=self.fetch)
        return json.loads(res)

    def process_file(self, path):
        content = path.read_text()
        res = j.evaluate_snippet(str(path), content, import_callback=self.fetch)
        return json.loads(res)
