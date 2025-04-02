
local components = import "components.jsonnet";

local apply = function(p, components)

    local base = {

        with_readme:: function() { },

    };

    local component = base + components[p.name];

    component.with_readme();

local readme = function(config)
    local add = function(state, c) state + apply(c, components);
    local patterns = std.foldl(add, config, {});
    patterns;

readme

