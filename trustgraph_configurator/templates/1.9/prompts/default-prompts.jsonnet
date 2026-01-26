
// Prompt templates.  For tidy JSONNET use, don't change these templates
// here, but use over-rides in the prompt directory

{

    "system-template":: "You are a helpful assistant.",

    "templates":: {

        "question":: {
            "prompt": "{{question}}",
        },

        "extract-definitions":: {
            "prompt": importstr "extract-definitions.txt",
            "response-type": "json",
            "schema": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "entity": {
                            "type": "string"
                        },
                        "definition": {
                            "type": "string"
                        }
                    },
                    "required": [
                        "entity",
                        "definition"
                    ]
                }
            }
        },

        "extract-relationships":: {
            "prompt": importstr "extract-relationships.txt",
            "response-type": "json",
            "schema": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "subject": {
                            "type": "string"
                        },
                        "predicate": {
                            "type": "string"
                        },
                        "object": {
                            "type": "string"
                        },
                        "object-entity": {
                            "type": "boolean"
                        },
                    },
                    "required": [
                        "subject",
                        "predicate",
                        "object",
                        "object-entity"
                    ]
                }
            }
        },

        "extract-topics":: {
            "prompt": importstr "extract-topics.txt",
            "response-type": "json",
            "schema": {
                "type": "array",
                "items": {
                    "type": "object",
                    "properties": {
                        "topic": {
                            "type": "string"
                        },
                        "definition": {
                            "type": "string"
                        }
                    },
                    "required": [
                        "topic",
                        "definition"
                    ]
                }
            }
        },

        "extract-rows":: {
            "prompt": importstr "extract-rows.txt",
            "response-type": "json",
        },

        "kg-prompt":: {
            "prompt": importstr "kg-prompt.txt",
            "response-type": "text",
        },

        "document-prompt":: {
            "prompt": importstr "document-prompt.txt",
            "response-type": "text",
        },

        "agent-react":: {
            "prompt": importstr "agent-prompt.txt",
            "response-type": "text"
        },

        "agent-kg-extract":: {
            "prompt": importstr "agent-kg-extract.txt",
            "response-type": "json",
            "schema": {
                "type": "object",
                "properties": {
                    "definitions": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "entity": {
                                    "type": "string"
                                },
                                "definition": {
                                    "type": "string"
                                }
                            },
                            "required": [
                                "entity",
                                "definition"
                            ]
                        }
                    },
                    "relationships": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "subject": {
                                    "type": "string"
                                },
                                "predicate": {
                                    "type": "string"
                                },
                                "object": {
                                    "type": "string"
                                },
                                "object-entity": {
                                    "type": "boolean"
                                }
                            },
                            "required": [
                                "subject",
                                "predicate",
                                "object"
                            ]
                        }
                    }
                },
                "required": [
                    "definitions",
                    "relationships"
                ]
            }
        },

        "schema-selection":: {
            "prompt": importstr "schema-selection.txt",
            "response-type": "json",
            "schema": {
                "type": "array",
                "items": {
                    "type": "string"
                },
                "description": "An array of schema names that are relevant to answering the given question"
            }
        },

        "graphql-generation":: {
            "prompt": importstr "graphql-generation.txt",
            "response-type": "json",
            "schema": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "The GraphQL query string generated to answer the question"
                    },
                    "variables": {
                        "type": "object",
                        "description": "Object containing any GraphQL variables needed for the query",
                        "additionalProperties": true
                    },
                    "confidence": {
                        "type": "number",
                        "minimum": 0.0,
                        "maximum": 1.0,
                        "description": "Float between 0.0-1.0 indicating confidence in the generated query"
                    }
                },
                "required": ["query", "variables", "confidence"],
                "additionalProperties": false
            }
        },

        "diagnose-structured-data":: {
            "prompt": importstr "diagnose-structured-data.txt",
            "response-type": "json",
        },

        "diagnose-xml":: {
            "prompt": importstr "diagnose-xml.txt",
            "response-type": "json",
        },
        "diagnose-json":: {
            "prompt": importstr "diagnose-json.txt",
            "response-type": "json",
        },
        "diagnose-csv":: {
            "prompt": importstr "diagnose-csv.txt",
            "response-type": "json",
        },

        "extract-with-ontologies":: {
            "prompt": importstr "ontology-prompt.txt",
            "response-type": "json",
        },

    }

}

