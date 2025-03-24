
import json
import logging
import argparse

from . import Generator, Packager

def run():

    logging.basicConfig(level=logging.INFO, format='%(message)s')

    parser = argparse.ArgumentParser(
        prog="tg-configurator",
        description=__doc__
    )

    parser.add_argument(
        '--version',
        required=True,
        help=f'Version'
    )

    parser.add_argument(
        '--input',
        default="config.json",
        help=f'Input configuration name (default: config.json)'
    )

    parser.add_argument(
        '--output',
        default="output.zip",
        help=f'Output file name (default: output.zip)'
    )

    parser.add_argument(
        '--template',
        default="0.21",
        help=f'Template to use'
    )

    parser.add_argument(
        '--platform',
        default="docker-compose",
        help=f'Platform (default: docker-compose)'
    )

    args = parser.parse_args()
    args = vars(args)

    input = args["input"]

    with open(input) as f:
        config = f.read()

    del args["input"]

    a = Packager(**args)
    a.generate(config)

