// Emits the docker-compose.yaml spec. Runs `create` against the
// docker-compose engine on every visible field of `patterns`, folding
// the returned resource fragments into a single compose document.
//
// No `objectHasAll(p, 'create')` guard here — if a visible sub-object
// lacks a `create::`, the fold crashes loudly with "Field does not
// exist: create". That's deliberate: such a sub-object is almost always
// a stub left behind by refactoring (e.g. a defaults-only block whose
// owning component has been merged elsewhere) and you want the build to
// fail rather than silently produce an incomplete deployment.

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

