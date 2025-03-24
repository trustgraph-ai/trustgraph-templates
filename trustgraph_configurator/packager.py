
import pathlib
import yaml
import logging
import importlib.resources
from io import BytesIO
import zipfile

from . import Generator

logger = logging.getLogger("packager")
logger.setLevel(logging.DEBUG)

class Packager:

    def __init__(self, version, output, template, platform):

        files = importlib.resources.files()

        self.version = version
        self.templates = files.joinpath("templates").joinpath(template)
        self.resources = files.joinpath("resources")
        self.platform = platform
        self.output = output

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
    
    def generate(self, config):

        logger.info(f"Generating for platform={self.platform} "
                    f"version={self.version}")

        try:

            if self.platform in set(["docker-compose", "podman-compose"]):
                data = self.generate_docker_compose(
                    "docker-compose", self.version, config
                )
            elif self.platform in set([
                    "minikube-k8s", "gcp-k8s", "aks-k8s", "eks-k8s"
            ]):
                data = self.generate_k8s(
                    self.platform, self.version, config
                )
            else:
                raise RuntimeError("Bad platform")

            with open(self.output, "wb") as f:
                f.write(data)

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

        processed = self.process(
            config, platform=platform, version=version
        )

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

