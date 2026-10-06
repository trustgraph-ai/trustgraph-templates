When you download the deploy configuration, you will have a ZIP file containing all the configuration needed to launch TrustGraph in Docker Compose. Unzip the ZIP file:

```bash
unzip deploy.zip
```

On MacOS, it may be necessary to specify a destination directory for the TrustGraph package:

```bash
unzip deploy.zip -d deploy
```

Navigate to the `docker-compose` directory. From this directory, launch TrustGraph with:

```bash
docker compose -f docker-compose.yaml up -d
```

You may need to fix permissions on files in the deploy bundle so that they are accessible from within containers.

```bash
find garage/ loki/ prometheus/ grafana/ trustgraph/ launch/ ui/ -type d | xargs chmod 755
find garage/ loki/ prometheus/ grafana/ trustgraph/ launch/ ui/ -type f | xargs chmod 644
```

On Linux with SELinux, you also need to set the container file context:

```bash
chcon -Rt svirt_sandbox_file_t garage/ loki/ prometheus/ grafana/ trustgraph/ launch/ ui/
```
