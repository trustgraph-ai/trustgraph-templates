// Emits the runtime `trustgraph/config.json` — the configuration
// document the TrustGraph runtime reads on startup (flows, prompts,
// active-flow defaults, and so on).
//
// Unlike the other renderers, this one does NOT walk `patterns` via
// engine.create. Instead, it reads a pre-built object at
// `patterns.configuration.configuration`, which is assembled by
// ../core/configuration.jsonnet (pulling together flow-builder,
// parameter-processor, default-prompts, etc.).
//
// The noop engine is imported for symmetry with the other renderers
// but is never actually invoked.

local engine = import "../engine/noop.jsonnet";
local decode = import "decode-config.jsonnet";
local components = import "../components.jsonnet";

// Import config
local config = import "config.json";

// Produce patterns from config
local patterns = decode(config);

// Extract configuration directly from patterns
patterns.configuration.configuration


