// Shared helper imported by every renderer. Turns a config list
// (array of {name, parameters}) into a single merged `patterns` object.
//
//   decode([
//       { name: "rabbitmq",       parameters: {} },
//       { name: "trustgraph-base",parameters: {} },
//       { name: "openai",         parameters: { "max-output-tokens": 8192 } },
//       { name: "override",       parameters: { "prompt-concurrency": 4 } },
//   ])
//
// For each config entry, we build `base + components[entry.name]` and
// call its `with_params(entry.parameters)`. The results are folded with
// `state + apply(c)`, producing a merged object whose visible fields
// are component instances carrying `create::` methods.
//
// `base` supplies a default `with_params` that plants each param as a
// hidden top-level field via `self + { [k] +:: v }`. Components can
// override `with_params` to route params elsewhere — the `override`
// component in components.jsonnet replaces the default with a
// passthrough into the top-level `parameters +::` block, which is the
// mechanism every tunable in the template tree reads from via
// `$.parameters[...]`.
//
// Note the init value of the inner foldl is `self`, not `{}`. With
// empty pars (the common case for non-override components), the fold
// returns `self`, and the outer `self + self` is a safe no-op.

local components = import "../components.jsonnet";

local apply = function(p, components)

    local base = {

        with:: function(k, v) self + {
            [k] +:: v
        },

        with_params:: function(pars)
            self + std.foldl(
                function(obj, par) obj.with(par.key, par.value),
                std.objectKeysValues(pars),
                self
            ),

    };

    local component = base + components[p.name];

    component.with_params(p.parameters);

local decode = function(config)
    local add = function(state, c) state + apply(c, components);
    local patterns = std.foldl(add, config, {});
    patterns;

decode

