
import dataclasses
import importlib
import json

@dataclasses.dataclass
class Platform:
    name: str
    description: str

@dataclasses.dataclass
class Template:
    name: str
    description: str
    version: str
    status: str

@dataclasses.dataclass
class Status:
    name: str
    description: str

class Index:

    @staticmethod
    def get_platforms():

        files = importlib.resources.files()
        index = files.joinpath("templates").joinpath("index.json")

        with open(index) as f:
            ix = json.load(f)

        return [
            Platform(
                name = v["name"],
                description = v["description"]
            )
            for v in ix["platforms"]
        ]

    @staticmethod
    def get_templates():

        files = importlib.resources.files()
        index = files.joinpath("templates").joinpath("index.json")

        with open(index) as f:
            ix = json.load(f)

        return [
            Template(
                name = v["name"],
                description = v["description"],
                version = v["version"],
                status = v["status"],
            )
            for v in ix["templates"]
        ]

    @staticmethod
    def get_statuses():

        files = importlib.resources.files()
        index = files.joinpath("templates").joinpath("index.json")

        with open(index) as f:
            ix = json.load(f)

        return [
            Status(
                name = v["name"],
                description = v["description"],
            )
            for v in ix["statuses"]
        ]
