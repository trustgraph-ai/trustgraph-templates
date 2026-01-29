// OpenVINO Model Definitions
// OpenVINO works with OpenVINO-optimized models from HuggingFace
// We have to use the model OpenVINO was initialized with

{
    "type": "string",
    "description": "LLM model to use",
    "default": "model",
    "enum": [
        {
            id: "model",
            description: "Pre-defined model"
        },
    ],
    "required": true
}
