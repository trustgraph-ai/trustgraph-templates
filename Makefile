
PACKAGE_VERSION=0.0.0
VERSION=0.0.0

all: container

package:
	python3 -m build --sdist --outdir pkgs

CONTAINER=localhost/config-svc
DOCKER=podman

container: package
	${DOCKER} build -f Containerfile -t ${CONTAINER}:${VERSION} \
	    --format docker

# On port 8081
run-container:
	${DOCKER} run -i -t -p 8081:8080 ${CONTAINER}:${VERSION}

