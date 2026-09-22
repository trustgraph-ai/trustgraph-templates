// No-op renderer. Same foldl shape as the compose renderers, but the
// engine is a stub whose methods return empty fragments. Useful for
// exercising the full decode → create pipeline without producing real
// output (e.g. for validation or debugging).

local engine = import "../engine/noop.jsonnet";
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

