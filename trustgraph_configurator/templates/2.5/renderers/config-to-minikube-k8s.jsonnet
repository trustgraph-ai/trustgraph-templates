// K8s output for minikube. Delegates to `engine.package(patterns)`
// from ../engine/minikube-k8s.jsonnet, same as the other k8s
// renderers. Defines a `trustgraph` namespace resource locally — note
// it's currently unused by the output expression; left in place as a
// template for reintroducing namespace creation if needed.

local engine = import "../engine/minikube-k8s.jsonnet";
local decode = import "decode-config.jsonnet";
local components = import "../components.jsonnet";

// Import config
local config = import "config.json";

// Produce patterns from config
local patterns = decode(config);

local ns = {
    apiVersion: "v1",
    kind: "Namespace",
    metadata: {
        name: "trustgraph",
    },
    "spec": {
    },
};

// Extract resources using the engine
local resourceList = engine.package(patterns);

resourceList

