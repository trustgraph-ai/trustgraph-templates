
import pathlib
import yaml
import json
import logging
import importlib.resources
from io import BytesIO
import zipfile
import os

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
            raise RuntimeError(
                "You must latest, latest-stable or select a template."
            )

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
        self.resources = files.joinpath("resources").joinpath(template)
        self.platform = platform

    def fetch(
            self, dir, filename
    ):

        if filename == "trustgraph/config.json":
            config = self.generate_trustgraph_config(self.config)
            config = json.dumps(config)
            path = self.templates.joinpath(dir, filename)
            return str(path), config.encode("utf-8")
        
        if filename == "config.json" and dir == "":
            path = self.templates.joinpath(dir, filename)
            return str(path), self.config.encode("utf-8")
        
        if filename == "version.jsonnet":
            path = self.templates.joinpath(dir, filename)
            return str(path), f"\"{self.version}\"".encode("utf-8")

        if dir:
            candidates = [
                self.templates.joinpath(dir, filename),
                self.templates.joinpath(filename),
                self.resources.joinpath(dir, filename),
                self.resources.joinpath(filename),
            ]
        else:
            candidates = [
                self.templates.joinpath(filename)
            ]

        try:

            if filename == "vertexai/private.json":
                private_json = "Put your GCP private.json here"
                return str(candidates[0]), (private_json.encode("utf-8"))

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

    def generate_trustgraph_config(self, config):

        config = config.encode("utf-8")

        gen = Generator(fetch=self.fetch)

        path = self.templates.joinpath(
            f"trustgraph-config.jsonnet"
        )
        wrapper = path.read_text()

        processed = gen.process(wrapper)

        return processed
    
    def generate_resources(self, config):

        config = config.encode("utf-8")

        gen = Generator(fetch=self.fetch)

        path = self.templates.joinpath(
            f"config-to-{self.platform}.jsonnet"
        )
        wrapper = path.read_text()

        processed = gen.process(wrapper)

        return processed
    
    def write(self, config, output):

        try:

            self.config = config
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
    
    def write_tg_config(self, config):
        """Output only the TrustGraph configuration to stdout"""
        try:
            self.config = config
            tg_config_json = self.generate_trustgraph_config(config)
            tg_config_file = json.dumps(tg_config_json, indent=4)
            print(tg_config_file)
        except Exception as e:
            logging.error(f"Exception: {e}")
            raise e
    
    def write_resources(self, config):
        """Output only the platform resources to stdout"""
        try:
            self.config = config
            
            if self.platform in set(["docker-compose", "podman-compose"]):
                compose_json = self.generate_resources(config)
                compose_file = yaml.dump(compose_json)
                print(compose_file)
            elif self.platform in set([
                    "minikube-k8s", "gcp-k8s", "aks-k8s", "eks-k8s",
                    "scw-k8s",
            ]):
                processed = self.generate_resources(config)
                y = yaml.dump(processed)
                print(y)
            else:
                raise RuntimeError("Bad platform")
                
        except Exception as e:
            logging.error(f"Exception: {e}")
            raise e

    def generate_docker_compose(self, platform, version, config):

        compose_json = self.generate_resources(config)
        compose_file = yaml.dump(compose_json)

        tg_config_json = self.generate_trustgraph_config(config)
        tg_config_file = json.dumps(tg_config_json, indent=4)

        mem = BytesIO()

        with zipfile.ZipFile(mem, mode='w') as out:

            def output(name, content):
                logger.info(f"Adding {name}...")
                out.writestr(name, content)

            output("docker-compose.yaml", compose_file)
            output("trustgraph/config.json", tg_config_file)

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

        processed = self.generate_resources(config)

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

