
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
        '-v', '--version',
        help=f'Version'
    )

    parser.add_argument(
        '-i', '--input',
        default="config.json",
        help=f'Input configuration name (default: config.json)'
    )

    parser.add_argument(
        '-o', '--output',
        default="output.zip",
        help=f'Output file name (default: output.zip)'
    )

    parser.add_argument(
        '-t', '--template',
        help=f'Template to use'
    )

    parser.add_argument(
        '-p', '--platform',
        default="docker-compose",
        help=f'Platform (default: docker-compose)'
    )

    parser.add_argument(
        '--latest',
        action='store_true',
        help="Latest version",
    )

    parser.add_argument(
        '--latest-stable',
        action='store_true',
        help="Latest stable version",
    )

    args = parser.parse_args()
    args = vars(args)

    input = args["input"]

    with open(input) as f:
        config = f.read()

    output = args["output"]

    del args["input"]
    del args["output"]

    a = Packager(**args)
    a.write(config, output)

