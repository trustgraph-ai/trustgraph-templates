#!/usr/bin/env python3

"""
Dump all possible pathways through a dialog flow YAML file.

Usage:
    python dump-flow-paths.py [flow-file]

Defaults to trustgraph_configurator/resources/dialog/trustgraph-flow.yaml
"""

import sys
import yaml
from pathlib import Path


DEFAULT_FLOW = (
    "trustgraph_configurator/resources/dialog/trustgraph-flow.yaml"
)


def load_flow(path):
    with open(path) as f:
        return yaml.safe_load(f)


def evaluate_condition(condition, state):
    """
    Evaluate a simple condition string against current state.
    Supports: =, !=, >=, <=, >, <
    """
    for op in (">=", "<=", "!=", "=", ">", "<"):
        if op in condition:
            parts = condition.split(op, 1)
            key = parts[0].strip()
            value = parts[1].strip().strip("'\"")
            state_value = state.get(key)
            if state_value is None:
                return False
            if op == "=":
                return state_value == value
            elif op == "!=":
                return state_value != value
            elif op == ">=":
                return state_value >= value
            elif op == "<=":
                return state_value <= value
            elif op == ">":
                return state_value > value
            elif op == "<":
                return state_value < value
    return False


def get_possible_values(step):
    """Return all possible values a step can produce."""
    input_def = step.get("input", {})
    input_type = input_def.get("type")

    if input_type == "select":
        return [opt["value"] for opt in input_def.get("options", [])]
    elif input_type == "toggle":
        return ["true", "false"]
    elif input_type == "number":
        return [str(input_def.get("default", 0))]
    return [None]


def walk_paths(steps, start, state=None, path=None):
    """
    Recursively walk all paths through the flow.
    Yields each complete path as a list of (step_id, chosen_value) tuples.
    """
    if state is None:
        state = {}
    if path is None:
        path = []

    step = steps.get(start)
    if step is None:
        yield path
        return

    transitions = step.get("transitions", [])
    if not transitions:
        for value in get_possible_values(step):
            yield path + [(start, value)]
        return

    state_key = step.get("state_key")
    values = get_possible_values(step)

    for value in values:
        new_state = dict(state)
        if state_key and value is not None:
            new_state[state_key] = value

        next_step = None
        for tr in transitions:
            condition = tr.get("when")
            if condition:
                if evaluate_condition(condition, new_state):
                    next_step = tr["next"]
                    break
            else:
                next_step = tr.get("next")
                break

        if next_step is None:
            yield path + [(start, value)]
        else:
            yield from walk_paths(
                steps, next_step, new_state,
                path + [(start, value)]
            )


def main():
    flow_path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_FLOW
    data = load_flow(flow_path)
    steps = data["steps"]
    start = data["flow"]["start"]

    paths = list(walk_paths(steps, start))

    print(f"Total paths: {len(paths)}\n")

    for i, path in enumerate(paths, 1):
        print(f"--- Path {i} ---")
        for step_id, value in path:
            title = steps[step_id].get("title", step_id)
            print(f"  {step_id}: {value}  ({title})")
        print()


if __name__ == "__main__":
    main()
