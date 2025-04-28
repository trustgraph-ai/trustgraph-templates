
import pathlib
import yaml
import logging
import importlib.resources
from io import BytesIO
import zipfile

from . import Generator
from . index import Index

logger = logging.getLogger("packager")
logger.setLevel(logging.DEBUG)

class Packager:

    def __init__(
            self, version, template, platform,
            latest, latest_stable,
    ):

        if latest:
            version = Index.get_latest().version
            template = Index.get_latest().name

        if latest_stable:
            version = Index.get_latest_stable().version
            template = Index.get_latest_stable().name

        if template is None:
            raise RuntimeError("Don't know which template to use")

        if version is None:
            versions = [
                v
                for v in Index.get_templates()
                if v.name == template
            ]
            if len(versions) < 1:
                raise RuntimeError(f"Template {template} not known")
            version = versions[-1].version

        files = importlib.resources.files()

        self.template = template
        self.version = version
        self.templates = files.joinpath("templates").joinpath(template)
        self.resources = files.joinpath("resources")
        self.platform = platform

    def process(
        self, config,
    ):

        config = config.encode("utf-8")

        gen = Generator(
            config, templates=self.templates, resources=self.resources,
            version=self.version
        )

        path = self.templates.joinpath(
            f"config-to-{self.platform}.jsonnet"
        )
        wrapper = path.read_text()

        processed = gen.process(wrapper)

        return processed
    
    def write(self, config, output):

        try:

            data = self.generate(config)

            print("Writing output file...")

            with open(output, "wb") as f:
                f.write(data)

            print(f"Wrote {output}.")

        except Exception as e:
            logging.error(f"Exception: {e}")
            raise e
   
    def generate(self, config):

        logger.info(f"Generating for platform={self.platform} "
                    f"template={self.template} "
                    f"version={self.version}")

        try:

            if self.platform in set(["docker-compose", "podman-compose"]):
                data = self.generate_docker_compose(
                    "docker-compose", self.version, config
                )
            elif self.platform in set([
                    "minikube-k8s", "gcp-k8s", "aks-k8s", "eks-k8s",
                    "scw-k8s",
            ]):
                data = self.generate_k8s(
                    self.platform, self.version, config
                )
            else:
                raise RuntimeError("Bad platform")

            return data

        except Exception as e:
            logging.error(f"Exception: {e}")
            raise e

    def generate_docker_compose(self, platform, version, config):

        processed = self.process(config)

        y = yaml.dump(processed)

        mem = BytesIO()

        with zipfile.ZipFile(mem, mode='w') as out:

            def output(name, content):
                logger.info(f"Adding {name}...")
                out.writestr(name, content)

            fname = "docker-compose.yaml"

            output(fname, y)

            # Grafana config
            path = self.resources.joinpath(
                "grafana/dashboards/dashboard.json"
            )
            res = path.read_text()
            output("grafana/dashboards/dashboard.json", res)

            path = self.resources.joinpath(
                "grafana/provisioning/dashboard.yml"
            )
            res = path.read_text()
            output("grafana/provisioning/dashboard.yml", res)

            path = self.resources.joinpath(
                "grafana/provisioning/datasource.yml"
            )
            res = path.read_text()
            output("grafana/provisioning/datasource.yml", res)

            # Prometheus config
            path = self.resources.joinpath(
                "prometheus/prometheus.yml"
            )
            res = path.read_text()
            output("prometheus/prometheus.yml", res)

        logger.info("Generation complete.")

        return mem.getvalue()

    def generate_k8s(self, platform, version, config):

        processed = self.process(config)

        y = yaml.dump(processed)

        mem = BytesIO()

        with zipfile.ZipFile(mem, mode='w') as out:

            def output(name, content):
                logger.info(f"Adding {name}...")
                out.writestr(name, content)

            fname = "resources.yaml"

            output(fname, y)

        logger.info("Generation complete.")

        return mem.getvalue()

