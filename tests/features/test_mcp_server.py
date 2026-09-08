"""Deployment contract for the TrustGraph MCP server."""

import pytest

from helpers import _entry, run_packager


pytestmark = pytest.mark.features


BASELINE_28 = [
    "rabbitmq",
    "trustgraph-base",
    "openai",
    "embeddings-fastembed",
    "cassandra",
    "triple-store-cassandra",
    "vector-store-qdrant",
    "garage",
    "mcp-server",
]


def build_mcp_deployment(api_gateway_port):
    config = [_entry(name) for name in BASELINE_28]
    config.append(_entry("override", {
        "api-gateway-port": api_gateway_port,
    }))
    resources, _ = run_packager(
        config,
        template="2.8",
        version="2.8.15",
    )
    return resources


def option_value(command, option):
    return command[command.index(option) + 1]


@pytest.mark.parametrize("api_gateway_port", [8088, 18088])
def test_mcp_server_uses_configured_api_gateway_port(api_gateway_port):
    resources = build_mcp_deployment(api_gateway_port)
    gateway_command = resources["services"]["api-gateway"]["command"]
    mcp_command = resources["services"]["mcp-server"]["command"]

    assert option_value(gateway_command, "--port") == str(api_gateway_port)
    assert option_value(mcp_command, "--websocket-url") == (
        f"ws://api-gateway:{api_gateway_port}/api/v1/socket"
    )
