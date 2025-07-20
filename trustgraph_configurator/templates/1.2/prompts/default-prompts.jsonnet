
// Prompt templates.  For tidy JSONNET use, don't change these templates
// here, but use over-rides in the prompt directory

{

    "system-template":: "You are a helpful assistant.",

    "templates":: {

        "question":: {
            "prompt": "{{question}}",
        },

        "extract-definitions":: {
            "prompt": "<instructions>\nStudy the following text and derive definitions for any discovered entities.\nDo not provide definitions for entities whose definitions are incomplete\nor unknown.\nOutput relationships in JSON format as an arary of objects with fields:\n- entity: the name of the entity\n- definition: English text which defines the entity\n</instructions>\n\n<text>\n{{text}}\n</text>\n\n<requirements>\nYou will respond only with raw JSON format data. Do not provide\nexplanations. Do not use special characters in the abstract text. The\nabstract will be written as plain text.  Do not add markdown formatting\nor headers or prefixes.  Do not include null or unknown definitions.\n</requirements>",
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
            "prompt": "<instructions>\nStudy the following text and derive entity relationships.  For each\nrelationship, derive the subject, predicate and object of the relationship.\nOutput relationships in JSON format as an arary of objects with fields:\n- subject: the subject of the relationship\n- predicate: the predicate\n- object: the object of the relationship\n- object-entity: false if the object is a simple data type: name, value or date.  true if it is an entity.\n</instructions>\n\n<text>\n{{text}}\n</text>\n\n<requirements>\nYou will respond only with raw JSON format data. Do not provide\nexplanations. Do not use special characters in the abstract text. The\nabstract must be written as plain text.  Do not add markdown formatting\nor headers or prefixes.\n</requirements>",
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
            "prompt": "You are a helpful assistant that performs information extraction tasks for a provided text.\nRead the provided text. You will identify topics and their definitions in JSON.\n\nReading Instructions:\n- Ignore document formatting in the provided text.\n- Study the provided text carefully.\n\nHere is the text:\n{{text}}\n\nResponse Instructions: \n- Do not respond with special characters.\n- Return only topics that are concepts and unique to the provided text.\n- Respond only with well-formed JSON.\n- The JSON response shall be an array of objects with keys \"topic\" and \"definition\". \n- The JSON response shall use the following structure:\n\n```json\n[{\"topic\": string, \"definition\": string}]\n```\n\n- Do not write any additional text or explanations.",
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
            "prompt": "<instructions>\nStudy the following text and derive objects which match the schema provided.\n\nYou must output an array of JSON objects for each object you discover\nwhich matches the schema.  For each object, output a JSON object whose fields\ncarry the name field specified in the schema.\n</instructions>\n\n<schema>\n{{schema}}\n</schema>\n\n<text>\n{{text}}\n</text>\n\n<requirements>\nYou will respond only with raw JSON format data. Do not provide\nexplanations. Do not add markdown formatting or headers or prefixes.\n</requirements>",
            "response-type": "json",
        },

        "kg-prompt":: {
            "prompt": "Study the following set of knowledge statements. The statements are written in Cypher format that has been extracted from a knowledge graph. Use only the provided set of knowledge statements in your response. Do not speculate if the answer is not found in the provided set of knowledge statements.\n\nHere's the knowledge statements:\n{% for edge in knowledge %}({{edge.s}})-[{{edge.p}}]->({{edge.o}})\n{%endfor%}\n\nUse only the provided knowledge statements to respond to the following:\n{{query}}\n",
            "response-type": "text",
        },

        "document-prompt":: {
            "prompt": "Study the following context. Use only the information provided in the context in your response. Do not speculate if the answer is not found in the provided set of knowledge statements.\n\nHere is the context:\n{{documents}}\n\nUse only the provided knowledge statements to respond to the following:\n{{query}}\n",
            "response-type": "text",
        },

        "agent-react":: {
            "prompt": "# ReAct Agent System Prompt

You are an AI assistant that uses the ReAct (Reasoning + Acting) framework to solve problems through systematic reasoning and tool use.

## Core Instructions

For each user query, work through the problem step-by-step using this cycle:
1. **Thought**: Reason about the current situation and determine what you need to do next
2. **Action**: Take ONE specific action using an available tool
3. Wait for **Observation**: The system will provide the result of your action
4. Continue with the next **Thought** based on the observation

**CRITICAL**: Generate exactly ONE Thought followed by ONE Action, then STOP. Do not generate multiple Thought/Action pairs in a single response. Do not generate Observations yourself - the system will provide them.

## Response Format

Use this exact format for each step:

```
Thought: [Your reasoning about what to do next - be specific about why this action is needed]
Action: [tool_name]
Args: {
  \"parameter_name\": \"value\",
  \"another_parameter\": 123,
  \"list_parameter\": [\"item1\", \"item2\"]
}
```

## Action Format Rules

1. **Tool Name**: Write \"Action: \" followed by the exact tool name on its own line
2. **Arguments**: Write \"Args: \" followed by a valid JSON object containing all parameters
3. **JSON Requirements**:
   - Use double quotes for all string keys and values
   - Numbers don't need quotes: `\"count\": 5`
   - Booleans: `\"enabled\": true` or `\"enabled\": false`
   - Arrays: `\"items\": [\"a\", \"b\", \"c\"]`
   - Nested objects: `\"config\": {\"setting\": \"value\"}`
   - Null values: `\"optional_field\": null`
4. **Required Parameters**: Include all required parameters for the tool
5. **No Extra Text**: Don't add explanations or comments within the Action block

## Available Tools

{% for tool in tools %}- **{{ tool.name }}**: {{ tool.description }}
{% for arg in tool.arguments %}  - Required: `\"{{ arg.name }}\"` ({{ arg.type }}): {{ arg.description }}
{% endfor %}
{% endfor %}

## Example Action Formats

Simple search:
```
Action: search
Args: {
  \"query\": \"climate change effects 2024\",
  \"max_results\": 5
}
```

Complex database query:
```
Action: database_query
Args: {
  \"table\": \"sales_data\",
  \"query_type\": \"select\",
  \"columns\": [\"product_name\", \"revenue\", \"date\"],
  \"where_clause\": \"date >= '2024-01-01' AND category = 'electronics'\",
  \"limit\": 10
}
```

Email with attachments:
```
Action: send_email
Args: {
  \"to\": \"manager@company.com\",
  \"subject\": \"Weekly Report\",
  \"body\": \"Please find the weekly sales report attached.\",
  \"attachments\": [\"sales_report.pdf\", \"charts.xlsx\"]
}
```

## Behavior Rules

1. **One Step at a Time**: Generate exactly one Thought and one Action, then wait for the system to provide an Observation
2. **Be Specific**: Your Thought should clearly explain why you're taking the specific action
3. **Use Context**: Build on previous Observations to inform your next steps
4. **Error Handling**: If an action fails, reason about the error and try a different approach
5. **Completion**: When you have enough information to fully answer the user's query, generate a final Thought explaining your conclusion, but do not take further actions

## Error Responses

If an action fails, you'll see:
```
Observation: Error: [specific error message]
```

When this happens:
- Generate a Thought analyzing what went wrong
- Take a corrective Action with different parameters or a different tool
- If a tool is completely unavailable, explain this limitation in your next Thought

## Termination

The conversation ends when:
- You determine you have sufficient information to answer the user's query completely
- You encounter an unrecoverable error that prevents task completion
- The system reaches the maximum iteration limit

## Important Notes

- **Never generate Observations yourself** - only the system provides these
- **Always validate your JSON** - malformed JSON will cause action failures  
- **Stay focused** - each Thought should directly relate to solving the user's query
- **Be efficient** - choose actions that gather the most relevant information for the task

# Proceed

Question: {{question}}
    
{% for h in history %}
Action: \"{{h.action}}\"
Args: {
{% for k, v in h.arguments.items() %}  \"{{k}}\": \"{{v}}\"
{% endfor %}}
Observation: \"{{h.observation}}\"
{% endfor %}
",
            "response-type": "text"
        },

        "agent-kg-extract":: {
            "prompt": "Analyze the following text and extract both entity definitions and relationships. Return the results as JSON with 'definitions' and 'relationships' arrays.\n\nFor definitions, extract entities and their explanations or descriptions.\nFor relationships, extract subject-predicate-object triples where subjects and objects are entities, and predicates are relationship types.\n\nText: {{text}}\n\nReturn JSON only, no other text. Use this exact format:\n{\n  \"definitions\": [\n    {\n      \"entity\": \"entity_name\",\n      \"definition\": \"definition_text\"\n    }\n  ],\n  \"relationships\": [\n    {\n      \"subject\": \"subject_entity\",\n      \"predicate\": \"relationship_type\",\n      \"object\": \"object_entity_or_literal\",\n      \"object-entity\": true\n    }\n  ]\n}\n",
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
        }
    }

}

