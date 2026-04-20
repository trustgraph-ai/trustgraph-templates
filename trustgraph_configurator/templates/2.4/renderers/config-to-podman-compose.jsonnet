// Podman-compose output. Identical to config-to-docker-compose.jsonnet
// — podman-compose consumes the same spec shape, so we import the same
// engine and run the same foldl over `patterns`.

local engine = import "../engine/docker-compose.jsonnet";
local decode = import "decode-config.jsonnet";
local components = import "../components.jsonnet";

// Import config
local config = import "config.json";

// Produce patterns from config
local patterns = decode(config);

// Extract resources usnig the engine
local resources = std.foldl(
    function(state, p) state + p.create(engine),
    std.objectValues(patterns),
    {}
);

resources

