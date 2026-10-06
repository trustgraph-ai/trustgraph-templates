When you download the deploy configuration, you will have a ZIP file containing all the configuration needed to launch TrustGraph in Podman Compose. Unzip the ZIP file:

```bash
unzip deploy.zip
```

Navigate to the `docker-compose` directory. From this directory, launch TrustGraph with:

```bash
podman compose -f docker-compose.yaml up -d
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
