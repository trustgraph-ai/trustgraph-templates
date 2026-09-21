// Emits the list of `launch/*/launch.yaml` files (and any other
// configVolume parts) that ship alongside the compose / k8s output.
//
// This renderer is unusual: instead of running `create` against a
// target-shaped engine, it uses a *collecting engine* whose methods are
// mostly no-ops except for `configVolume`, which captures the `parts`
// argument into `configVolumes` on the accumulating state. The renderer
// then walks that list and converts it into an `[{path, content}, ...]`
// array for the Packager to drop into the zip at the right paths.
//
// Unlike the compose renderers, this one guards with
// `std.objectHasAll(p, 'create')` so hidden-only sub-objects (e.g.
// `parameters`) don't crash the fold.

local decode = import "decode-config.jsonnet";

// Import config
local config = import "config.json";

// Produce patterns from config
local patterns = decode(config);

// Collecting engine: every method is a no-op except configVolume,
// which captures {dir, parts} into a plain array.
local engine = {

    container:: function(name) {
        with_image:: function(x) self,
        with_command:: function(x) self,
        with_environment:: function(x) self,
        with_limits:: function(c, m) self,
        with_reservations:: function(c, m) self,
        with_port:: function(src, dest, name) self,
        with_volume_mount:: function(vol, mnt) self,
        with_user:: function(x) self,
        with_group:: function(x) self,
        with_supplemental_group:: function(x) self,
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

    configVolume:: function(name, dir, parts) {
        name: name,
        dir:: dir,
        parts:: parts,
        with_size:: function(size) self,
    },

    secretVolume:: function(name, dir, parts) {
        with_size:: function(size) self,
    },

    envSecrets:: function(name) {
        with_env_var:: function(name, key) self,
    },

    containers:: function(name, containers) {
        with_replicas:: function(n) self,
    },

    internalService:: function(name, containers) {
        with_port:: function(src, dest, name) self,
    },

    service:: function(name, containers) {
        with_port:: function(src, dest, name) self,
    },

    resources:: function(res)
        [
            { dir: r.dir, parts: r.parts }
            for r in res
            if std.objectHasAll(r, 'parts')
        ],
};

// Evaluate each component independently against a fresh engine.
// No fold, no accumulated state — each create() gets a clean engine.
local perComponent = [
    p.create(engine)
    for p in std.objectValues(patterns)
    if std.objectHasAll(p, 'create')
];

// Each create() returns the engine.resources() output: an array of
// {dir, parts} objects. Flatten them all together.
local allConfigVolumes = std.flattenArrays(perComponent);

// Transform collected data into output format
local allFiles = std.flattenArrays([
    [
        {
            path: std.join("/", [std.rstripChars(cv.dir, "/"), filename]),
            content: cv.parts[filename]
        }
        for filename in std.objectFields(cv.parts)
    ]
    for cv in allConfigVolumes
]);

// Deduplicate by path — last writer wins
local uniqueMap = std.foldl(
    function(acc, item) acc + { [item.path]: item },
    allFiles,
    {}
);

std.objectValues(uniqueMap)
