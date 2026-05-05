
local k8s = import "k8s.jsonnet";

// gp3 with 6000 IOPS / 400 MiB/s requires minimum 16 GiB
// (500 IOPS-per-GiB ratio needs 12 GiB; throughput floor needs 16 GiB).
local minGib = 16;

local parseGib = function(s)
    if std.endsWith(s, "Gi") then
        std.parseJson(std.substr(s, 0, std.length(s) - 2))
    else if std.endsWith(s, "G") then
        std.parseJson(std.substr(s, 0, std.length(s) - 1))
    else if std.endsWith(s, "Mi") then
        std.parseJson(std.substr(s, 0, std.length(s) - 2)) / 1024
    else if std.endsWith(s, "M") then
        std.parseJson(std.substr(s, 0, std.length(s) - 1)) / 1024
    else 0;

local floorSize = function(s)
    local g = parseGib(s);
    if g < minGib then "" + minGib + "Gi" else s;

local ns = {
    apiVersion: "v1",
    kind: "Namespace",
    metadata: {
        name: "trustgraph",
    },
    "spec": {
    },
};

local sc = {
    apiVersion: "storage.k8s.io/v1",
    kind: "StorageClass",
    metadata: {
        name: "tg",
    },
    provisioner: "ebs.csi.aws.com",
    parameters: {
        type: "gp3",
        encrypted: "true",
        iops: "6000",
        throughput: "400",
    },
    reclaimPolicy: "Delete",
    volumeBindingMode: "WaitForFirstConsumer",
};

k8s + {

    volume:: function(name)
        local base = k8s.volume(name);
        base + {
            add:: function()
                local vol = self;
                local patched = base { size: floorSize(vol.size) };
                patched.add(),
        },

    // Extract resources usnig the engine
    package:: function(patterns)
        local resources = [sc, ns] + std.flattenArrays([
            p.create(self) for p in std.objectValues(patterns)
        ]);
        local resourceList = {
            apiVersion: "v1",
            kind: "List",
            items: resources,
        };
        resourceList

}

