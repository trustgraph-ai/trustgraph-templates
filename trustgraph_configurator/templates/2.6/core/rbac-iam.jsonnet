local images = import "values/images.jsonnet";

{

    "control" +: {
        "control-image":: images.trustgraph_enterprise,
        "iam-processor-class":: "trustgraph.rbac.service.Processor",
    },

}
