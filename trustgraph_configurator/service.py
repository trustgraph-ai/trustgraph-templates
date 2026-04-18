"""
CLI entry point for `tg-config-svc`.

Starts the aiohttp-based HTTP service (see api.py) that exposes the
configurator as a REST API: POST /api/generate/{platform}/{template}
to build a deployment zip from a supplied config, plus GET endpoints
for version discovery and the bundled dialog-flow / docs resources.
"""

import logging

from . api import Api

def run_service():

    logging.basicConfig(
        level=logging.DEBUG,
        format="%(asctime)s %(levelname)s %(message)s"
    )

    logging.info("Starting...")

    a = Api(port=8080)

    a.run()

