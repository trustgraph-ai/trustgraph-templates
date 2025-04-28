
# TrustGraph configuration templates

## List configurations

```
export PYTHONPATH=.
scripts/tg-configurations-list
```

## Build configurations

```
export PYTHONPATH=.
scripts/tg-configurator --template 0.21 --version 0.21.17 \
    --input config.json --output output.zip
```

