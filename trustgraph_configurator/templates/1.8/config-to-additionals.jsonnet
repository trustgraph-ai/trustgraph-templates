local decode = import "util/decode-config.jsonnet";

// Import config
local config = import "config.json";

// Produce patterns from config
local patterns = decode(config);

// Custom engine that collects configVolume parts
local engine = {

    // Collection of all configVolume parts
    configVolumes:: [],

    // Implement all required engine methods as no-ops
    container:: function(name) {
        with_image:: function(x) self,
        with_command:: function(x) self,
        with_environment:: function(x) self,
        with_limits:: function(c, m) self,
        with_reservations:: function(c, m) self,
        with_port:: function(src, dest, name) self,
        with_volume_mount:: function(vol, mnt) self,
        with_user:: function(x) self,
        with_runtime:: function(x) self,
        with_privileged:: function(x) self,
        with_ipc:: function(x) self,
        with_capability:: function(x) self,
        with_device:: function(hdev, cdev) self,
        with_env_var_secrets:: function(vars) self,
    },

    volume:: function(name) {
        with_size:: function(size) self,
    },

    // The key method - collects configVolume parts
    configVolume:: function(name, dir, parts)
        local collector = self + {
            configVolumes: super.configVolumes + [
                {
                    dir: dir,
                    parts: parts,
                }
            ]
        };
        {
            // Return a dummy volume that has the collector in it
            name: name,
            with_size:: function(size) collector,
            // Provide a way to get back to the collector
            getCollector:: function() collector,
        },

    secretVolume:: function(name, dir, parts) {
        with_size:: function(size) self,
    },

    envSecrets:: function(name) {
        with_env_var:: function(name, key) self,
    },

    containers:: function(name, containers) self,

    service:: function(containers) {
        with_port:: function(src, dest, name) self,
    },

    internalService:: function(containers) {
        with_port:: function(src, dest, name) self,
    },

    resources:: function(res)
        // Fold over resources and collect any configVolume state
        local collected = std.foldl(
            function(state, r)
                if std.objectHas(r, 'getCollector') then
                    r.getCollector()
                else
                    state,
            res,
            self
        );
        collected,
};

// Execute all component create() functions with our collecting engine
local result = std.foldl(
    function(state, p)
        local created = p.create(state);
        // Return the engine state (which accumulates configVolumes)
        created,
    std.objectValues(patterns),
    engine
);

// Transform collected data into output format
local additionals = std.flattenArrays([
    [
        {
            path: std.join("/", [cv.dir, filename]),
            content: cv.parts[filename]
        }
        for filename in std.objectFields(cv.parts)
    ]
    for cv in result.configVolumes
]);

// Output the array
additionals
