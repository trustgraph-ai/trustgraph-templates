// Interface Builder Module
// Processes flow class interfaces with parameter substitution
// Handles both string interfaces and nested object interfaces

local param_processor = import "parameter-processor.jsonnet";
local default_workspace = "default";

{
    // Builds interfaces for a specific flow class and instance
    // Processes the 'interfaces' section of flow classes
    build_interfaces: function(flow_classes, class_name, flow_id, parameters)
        local interface_spec = flow_classes[class_name].interfaces;
        local substitute = function(s)
            local class_replaced = std.strReplace(s, "{class}", class_name);
            local workspace_replaced = std.strReplace(
                class_replaced, "{workspace}", default_workspace
            );
            local id_replaced = std.strReplace(
                workspace_replaced, "{id}", flow_id
            );
            param_processor.substitute_parameters(id_replaced, parameters);
        {
            [interface.key]:
                if std.isString(interface.value) then
                    // Simple string interface - apply all substitutions
                    substitute(interface.value)
                else
                    // Complex object interface - process nested fields
                    {
                        [field.key]: substitute(field.value)
                        for field in std.objectKeysValuesAll(interface.value)
                    }
            for interface in std.objectKeysValuesAll(interface_spec)
        },
}