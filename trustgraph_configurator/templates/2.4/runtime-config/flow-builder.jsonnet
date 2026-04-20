// Flow Builder Module
// Processes flow blueprints and builds complete flow configurations
// Handles {blueprint}, {id}, and parameter substitutions

local param_processor = import "parameter-processor.jsonnet";
local default_workspace = "default";

{
    // Recursively apply {blueprint}, {id}, and parameter substitutions
    // to a value. Strings are replaced directly; objects recurse into
    // their fields so that the topics/parameters sub-objects are handled
    // transparently.
    _replace_value: function(v, blueprint_name, flow_id, parameters)
        if std.isString(v) then
            local br = std.strReplace(v, "{blueprint}", blueprint_name);
            local wr = std.strReplace(br, "{workspace}", default_workspace);
            local ir = if flow_id != null then std.strReplace(wr, "{id}", flow_id) else wr;
            param_processor.substitute_parameters(ir, parameters)
        else if std.isObject(v) then
            {
                [k]: $._replace_value(v[k], blueprint_name, flow_id, parameters)
                for k in std.objectFieldsAll(v)
            }
        else
            v,

    // Builds blueprint-level processors with parameter substitution
    // Processes the 'blueprint' section of flow blueprints
    build_blueprint_processors: function(flow_blueprints, blueprint_name, parameters)
        [
            [
                local key = std.strReplace(processor.key, "{blueprint}", blueprint_name);
                local parts = std.splitLimit(key, ":", 2);
                parts,
                {
                    [field.key]:
                        $._replace_value(field.value, blueprint_name, null, parameters)
                    for field in std.objectKeysValuesAll(processor.value)
                }
            ]
            for processor in std.objectKeysValuesAll(flow_blueprints[blueprint_name].blueprint)
        ],

    // Builds flow-level processors with parameter substitution
    // Processes the 'flow' section of flow blueprints
    build_flow_processors: function(flow_blueprints, blueprint_name, flow_id, parameters)
        [
            [
                local key = std.strReplace(
                    std.strReplace(
                        std.strReplace(
                            processor.key, "{workspace}", default_workspace
                        ),
                        "{blueprint}", blueprint_name
                    ),
                    "{id}", flow_id
                );
                local parts = std.splitLimit(key, ":", 2);
                parts,
                {
                    [field.key]:
                        $._replace_value(field.value, blueprint_name, flow_id, parameters)
                    for field in std.objectKeysValuesAll(processor.value)
                }
            ]
            for processor in std.objectKeysValuesAll(flow_blueprints[blueprint_name].flow)
        ],

    // Combines blueprint and flow processors into flow objects.
    // Each processor becomes its own config type keyed as
    // "processor:<name>", with flow variants as sub-keys.
    build_flow_objects: function(processor_array)
        std.map(
            function(item) {
                ["processor:" + item[0][0]] +: {
                    [item[0][1]]: item[1]
                }
            },
            processor_array
        ),

    // Merges all flow objects into a single flows_active configuration
    merge_flow_objects: function(flow_objects)
        std.foldr(
            function(a, b) a + b,
            flow_objects,
            {}
        ),
}
