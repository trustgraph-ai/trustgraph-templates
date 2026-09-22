
local k8s = import "k8s.jsonnet";

// Alibaba Cloud ACK cloud disks have a 20 GiB minimum size. The CSI driver
// measures the floor in binary GiB, so a decimal "20G" request (~18.6 GiB) is
// rejected. parseGib converts every unit to GiB - decimal G/M via the 1000 vs
// 1024 ratio - so floorSize lifts anything short of 20 GiB up to "20Gi".
local minGib = 20;

local parseGib = function(s)
    if std.endsWith(s, "Gi") then
        std.parseJson(std.substr(s, 0, std.length(s) - 2))
    else if std.endsWith(s, "Mi") then
        std.parseJson(std.substr(s, 0, std.length(s) - 2)) / 1024
    else if std.endsWith(s, "G") then
        std.parseJson(std.substr(s, 0, std.length(s) - 1)) * 1000000000 / 1073741824
    else if std.endsWith(s, "M") then
        std.parseJson(std.substr(s, 0, std.length(s) - 1)) * 1000000 / 1073741824
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
    provisioner: "diskplugin.csi.alibabacloud.com",
    parameters: {
        type: "cloud_essd",
        "csi.storage.k8s.io/fstype": "ext4",
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
