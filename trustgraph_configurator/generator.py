
import _jsonnet as j
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
