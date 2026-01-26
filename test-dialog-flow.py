#!/usr/bin/env python3
"""
Test harness for dialog flow - walks through selecting all default options,
produces the resulting state object, and runs the JSONata transform.

Supports a test matrix mode where each field is tested with all its options
while other fields use defaults.
"""

import yaml
import json
import argparse
from pathlib import Path
import jsonata


RESOURCES_DIR = Path(__file__).parent / "trustgraph_configurator/resources/dialog"


def load_flow():
    """Load the dialog flow YAML file."""
    with open(RESOURCES_DIR / "trustgraph-flow.yaml") as f:
        return yaml.safe_load(f)


def load_jsonata_transform():
    """Load the JSONata transform file."""
    with open(RESOURCES_DIR / "trustgraph-output.jsonata") as f:
        return f.read()


def run_transform(state, transform_expr):
    """Run the JSONata transform on the state object."""
    expr = jsonata.Jsonata(transform_expr)
    return expr.evaluate(state)


def get_all_options(step):
    """Get all possible values for a step's input."""
    input_def = step.get("input", {})
    input_type = input_def.get("type")

    if input_type == "select":
        return [opt["value"] for opt in input_def.get("options", [])]
    elif input_type == "toggle":
        return [True, False]
    elif input_type == "number":
        # For numbers, just test default, min, and max
        default = input_def.get("default")
        min_val = input_def.get("min")
        max_val = input_def.get("max")
        values = []
        if min_val is not None:
            values.append(min_val)
        if default is not None and default not in values:
            values.append(default)
        if max_val is not None and max_val not in values:
            values.append(max_val)
        return values

    return []


def get_default_value(step):
    """Get the default value for a step's input."""
    input_def = step.get("input", {})
    input_type = input_def.get("type")

    if input_type == "select":
        options = input_def.get("options", [])
        # Find recommended option, or use first
        for opt in options:
            if opt.get("recommended"):
                return opt["value"]
        return options[0]["value"] if options else None

    elif input_type == "number":
        return input_def.get("default")

    elif input_type == "toggle":
        return input_def.get("default", False)

    return None


def evaluate_condition(condition, state):
    """
    Evaluate a simple condition against the state.
    Supports: "key = value", "key = true/false", "key < 'version'"
    """
    if not condition:
        return True

    # Handle equality: "ocr.enabled = true"
    if " = " in condition:
        key, value = condition.split(" = ", 1)
        key = key.strip()
        value = value.strip()

        # Get nested key
        state_value = state.get(key)

        # Parse value
        if value == "true":
            return state_value is True
        elif value == "false":
            return state_value is False
        else:
            return str(state_value) == value

    # Handle less-than for version comparisons: "version < '1.6.0'"
    if " < " in condition:
        key, value = condition.split(" < ", 1)
        key = key.strip()
        value = value.strip().strip("'\"")
        state_value = state.get(key, "")
        return str(state_value) < value

    return False


def get_next_step(step, state):
    """Determine the next step based on transitions and current state."""
    transitions = step.get("transitions", [])

    for trans in transitions:
        when = trans.get("when")
        if when:
            if evaluate_condition(when, state):
                return trans.get("next")
        else:
            # Unconditional transition
            return trans.get("next")

    return None  # Terminal state


def walk_flow(flow_data, overrides=None, verbose=True):
    """
    Walk through the flow, return the state object.

    Args:
        flow_data: The parsed dialog flow YAML
        overrides: Dict of {state_key: value} to override defaults
        verbose: Whether to print progress
    """
    state = {}
    overrides = overrides or {}
    steps = flow_data.get("steps", {})
    current = flow_data.get("flow", {}).get("start")
    visited_steps = []

    if verbose:
        print(f"Starting at: {current}")
        print("-" * 60)

    while current:
        step = steps.get(current)
        if not step:
            if verbose:
                print(f"ERROR: Step '{current}' not found!")
            break

        visited_steps.append(current)
        title = step.get("title", current)
        state_key = step.get("state_key")

        # Get value - use override if present, otherwise default
        if state_key:
            if state_key in overrides:
                value = overrides[state_key]
            else:
                value = get_default_value(step)
            state[state_key] = value

            if verbose:
                is_override = state_key in overrides
                marker = " [OVERRIDE]" if is_override else ""
                print(f"Step: {current}")
                print(f"  Title: {title}")
                print(f"  State key: {state_key} = {value}{marker}")
        else:
            if verbose:
                print(f"Step: {current}")
                print(f"  Title: {title}")
                print(f"  (no state key - review/terminal step)")

        # Get next step
        next_step = get_next_step(step, state)
        if verbose:
            if next_step:
                print(f"  -> Next: {next_step}")
            else:
                print(f"  -> Terminal state")
            print()

        current = next_step

    return state, visited_steps


def collect_all_fields(flow_data):
    """
    Collect all fields and their possible values from the flow.
    Returns a list of (step_name, state_key, options, default_value) tuples.
    """
    fields = []
    steps = flow_data.get("steps", {})

    # Walk with defaults to find the baseline path
    _, visited = walk_flow(flow_data, verbose=False)

    for step_name in visited:
        step = steps.get(step_name, {})
        state_key = step.get("state_key")
        if state_key:
            options = get_all_options(step)
            default = get_default_value(step)
            if len(options) > 1:  # Only include fields with choices
                fields.append((step_name, state_key, options, default))

    return fields


def run_test_matrix(flow_data, transform_expr):
    """
    Run the test matrix - for each field, try all values while others use defaults.
    """
    fields = collect_all_fields(flow_data)

    print("=" * 70)
    print("TEST MATRIX")
    print("=" * 70)
    print()
    print(f"Found {len(fields)} fields with multiple options:")
    for step_name, state_key, options, default in fields:
        print(f"  - {state_key}: {len(options)} options (default: {default})")
    print()

    results = []
    test_num = 0

    # First, run the baseline (all defaults)
    test_num += 1
    print("-" * 70)
    print(f"Test {test_num}: BASELINE (all defaults)")
    print("-" * 70)
    state, _ = walk_flow(flow_data, verbose=False)
    config = run_transform(state, transform_expr)
    results.append({
        "test": test_num,
        "description": "BASELINE (all defaults)",
        "overrides": {},
        "state": state,
        "config": config
    })
    print(f"State: {json.dumps(state, indent=2)}")
    print(f"Templates: {[t['name'] for t in config['templates']]}")
    print()

    # For each field, try each non-default value
    for step_name, state_key, options, default in fields:
        for option in options:
            if option == default:
                continue  # Skip default, already tested in baseline

            test_num += 1
            print("-" * 70)
            print(f"Test {test_num}: {state_key} = {option}")
            print("-" * 70)

            # Build overrides - just this one field
            overrides = {state_key: option}

            # For toggles that enable conditional steps, we need defaults for those too
            # The walk_flow will handle this automatically

            state, _ = walk_flow(flow_data, overrides=overrides, verbose=False)

            try:
                config = run_transform(state, transform_expr)
                results.append({
                    "test": test_num,
                    "description": f"{state_key} = {option}",
                    "overrides": overrides,
                    "state": state,
                    "config": config
                })
                print(f"State: {json.dumps(state, indent=2)}")
                print(f"Templates: {[t['name'] for t in config['templates']]}")
            except Exception as e:
                results.append({
                    "test": test_num,
                    "description": f"{state_key} = {option}",
                    "overrides": overrides,
                    "state": state,
                    "error": str(e)
                })
                print(f"State: {json.dumps(state, indent=2)}")
                print(f"ERROR: {e}")
            print()

    return results


def main():
    parser = argparse.ArgumentParser(
        description="Test harness for dialog flow configuration"
    )
    parser.add_argument(
        "--matrix", "-m",
        action="store_true",
        help="Run test matrix (each field with all options)"
    )
    parser.add_argument(
        "--summary", "-s",
        action="store_true",
        help="Show summary only (with --matrix)"
    )
    args = parser.parse_args()

    flow_data = load_flow()
    transform_expr = load_jsonata_transform()

    if args.matrix:
        results = run_test_matrix(flow_data, transform_expr)

        # Summary
        print("=" * 70)
        print("SUMMARY")
        print("=" * 70)
        print()
        passed = [r for r in results if "error" not in r]
        failed = [r for r in results if "error" in r]
        print(f"Total tests: {len(results)}")
        print(f"Passed: {len(passed)}")
        print(f"Failed: {len(failed)}")

        if failed:
            print()
            print("Failed tests:")
            for r in failed:
                print(f"  - Test {r['test']}: {r['description']}")
                print(f"    Error: {r['error']}")
    else:
        print("=" * 60)
        print("Dialog Flow Test Harness - Default Options")
        print("=" * 60)
        print()

        state, _ = walk_flow(flow_data)

        print("=" * 60)
        print("Final State Object:")
        print("=" * 60)
        print()
        print(json.dumps(state, indent=2))

        # Run JSONata transform
        print()
        print("=" * 60)
        print("Running JSONata Transform...")
        print("=" * 60)
        print()

        config = run_transform(state, transform_expr)

        print("=" * 60)
        print("Configuration Object (output of transform):")
        print("=" * 60)
        print()
        print(json.dumps(config, indent=2))


if __name__ == "__main__":
    main()
