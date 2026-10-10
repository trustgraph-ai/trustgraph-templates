
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
    announcement: str = None

@dataclasses.dataclass
class AffectedRange:
    template: str
    versions: str
    fixed_in: str = None

@dataclasses.dataclass
class Advisory:
    id: str
    severity: str
    summary: str
    description: str
    url: str
    affects: list

@dataclasses.dataclass
class Status:
    name: str
    description: str

def version_unpack(v):
    return [v for v in map(int, v.split('.'))]

def version_sort(x):
    return sorted(x, key=lambda s: version_unpack(s))

def version_compare(a, b):
    return version_unpack(a) < version_unpack(b)

def version_matches(version, spec):
    """Check if a version matches a spec like '<2.8.15' or '>=2.7.0'."""
    import re
    m = re.match(r'^([<>]=?)\s*(.+)$', spec.strip())
    if not m:
        return False
    op, target = m.group(1), m.group(2)
    v = version_unpack(version)
    t = version_unpack(target)
    if op == '<': return v < t
    if op == '<=': return v <= t
    if op == '>': return v > t
    if op == '>=': return v >= t
    return False

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
                announcement = v.get("announcement"),
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

    @staticmethod
    def get_stable():

        return [
            v
            for v in filter(
                    lambda x: x.status == "stable", Index.get_templates()
            )
        ]

    @staticmethod
    def sort_versions(versions):
        return sorted(
            versions,
            key=lambda x: version_unpack(x.version)
        )

    @staticmethod
    def get_latest():
        v = Index.sort_versions(Index.get_templates())

        if len(v) < 1:
            raise RuntimeError("No latest version")

        return v[-1]

    @staticmethod
    def get_latest_stable():
        v = Index.sort_versions(Index.get_stable())

        if len(v) < 1:
            raise RuntimeError("No latest stable version")

        return v[-1]

    @staticmethod
    def get_advisories():

        files = importlib.resources.files()
        index = files.joinpath("templates").joinpath("advisories.json")

        with open(index) as f:
            data = json.load(f)

        return [
            Advisory(
                id=a["id"],
                severity=a["severity"],
                summary=a["summary"],
                description=a["description"],
                url=a["url"],
                affects=[
                    AffectedRange(
                        template=af["template"],
                        versions=af["versions"],
                        fixed_in=af.get("fixed_in"),
                    )
                    for af in a["affects"]
                ],
            )
            for a in data.get("advisories", [])
        ]

