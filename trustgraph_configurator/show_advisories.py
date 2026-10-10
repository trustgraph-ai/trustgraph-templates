
import argparse
import tabulate

from . import Index
from .index import version_unpack, version_matches


def show_advisories():

    parser = argparse.ArgumentParser(
        prog="tg-show-advisories",
        description="Show security advisories bundled with this package."
    )

    parser.add_argument(
        "-v", "--version",
        help="Only show advisories affecting this version, e.g. 2.8.3",
    )

    parser.add_argument(
        "--variant-id",
        help="Variant ID (reserved for future use)",
    )

    args = parser.parse_args()

    advisories = Index.get_advisories()

    if not advisories:
        print()
        print("No advisories.")
        print()
        return

    if args.version:

        try:
            parts = version_unpack(args.version)
        except:
            print(f"Invalid version format: {args.version}")
            return

        major = f"{parts[0]}.{parts[1]}"

        filtered = []
        for advisory in advisories:
            for af in advisory.affects:
                if af.template == major and version_matches(
                    args.version, af.versions
                ):
                    filtered.append(advisory)
                    break

        advisories = filtered

    if not advisories:
        print()
        print(f"No advisories affecting version {args.version}.")
        print()
        return

    rows = []
    for a in advisories:
        affected = []
        for af in a.affects:
            line = f"{af.template} {af.versions}"
            if af.fixed_in:
                line += f" (fixed in {af.fixed_in})"
            else:
                line += " (no fix)"
            affected.append(line)

        rows.append((
            a.id,
            a.severity,
            a.summary,
            "\n".join(affected),
            a.url,
        ))

    print()
    print(tabulate.tabulate(
        rows,
        tablefmt="pretty",
        headers=["id", "severity", "summary", "affects", "url"],
        maxcolwidths=[None, None, 40, 30, 50],
        stralign="left",
    ))
    print()
