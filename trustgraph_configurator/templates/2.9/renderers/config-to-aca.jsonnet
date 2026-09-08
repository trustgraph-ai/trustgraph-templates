// ARM template output targeting Azure Container Apps. Delegates to
// `engine.package(patterns)` from ../engine/aca.jsonnet, which owns
// the per-component walk and wraps the result in an ARM template
// envelope.
local engine = import "../engine/aca.jsonnet";
local decode = import "decode-config.jsonnet";
local components = import "../components.jsonnet";

local config = import "config.json";

local patterns = decode(config);

engine.package(patterns)
