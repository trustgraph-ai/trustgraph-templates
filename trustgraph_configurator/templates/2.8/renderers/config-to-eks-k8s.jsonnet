
// K8s output for EKS (AWS Elastic Kubernetes Service). Delegates to `engine.package(patterns)` from
// ../engine/eks-k8s.jsonnet, which owns the per-component walk and emits a
// list of k8s resource manifests. The k8s engines handle traversal
// internally rather than using the `objectValues + foldl + create`
// pattern the compose renderers use.
local engine = import "../engine/eks-k8s.jsonnet";
local decode = import "decode-config.jsonnet";
local components = import "../components.jsonnet";

// Import config
local config = import "config.json";

// Produce patterns from config
local patterns = decode(config);

// Extract resources usnig the engine
local resourceList = engine.package(patterns);

resourceList

