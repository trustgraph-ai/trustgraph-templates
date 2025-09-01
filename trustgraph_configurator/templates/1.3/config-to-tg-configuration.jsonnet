
local engine = import "engine/noop.jsonnet";
local decode = import "util/decode-config.jsonnet";
local components = import "components.jsonnet";

// Import config
local config = import "config.json";

// Produce patterns from config
local patterns = decode(config);

// Extract resources
local resources = std.foldl(
    function(state, p) state + p,
    std.objectValues(patterns),
    {}
);

local c = resources.configuration.mcp;

c

