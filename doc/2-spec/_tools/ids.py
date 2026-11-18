#!/usr/bin/env python3
"""Specification identifier registry.

Scans doc/2-spec for identifier definitions such as [[UC-ORD-001]], then

* writes one attribute file per document, so that {UC-ORD-001} becomes a link
  (internal when the identifier lives in the same document, cross-PDF otherwise);
* writes the registry (JSON) and the traceability tables (AsciiDoc) under 9-generated/spec;
* fails when an identifier is defined twice, referenced but never defined,
  or breaks a traceability rule.

Everything written by this script is derived and can be deleted and regenerated.
"""

from __future__ import annotations

import json
import re
import sys
from collections import defaultdict
from pathlib import Path

SPEC = Path(__file__).resolve().parent.parent
GEN = SPEC.parent / "9-generated" / "spec"

# Identifier types, in traceability order (upstream first).
TYPES = {
    "JRN": "Business journeys",
    "CP": "Critical paths",
    "BPMN": "Business processes",
    "EPIC": "Epics",
    "US": "User stories",
    "UC": "Use cases",
    "FR": "Functional requirements and business rules",
    "NFR": "Non-functional requirements",
    "BDD": "BDD acceptance scenarios",
    "CMD": "Commands",
    "EVT": "Events",
    "SC": "Saga scenarios",
    "ERR": "Error codes",
    "ADR": "Architecture decision records",
    "AR": "Architecture rules (ArchUnit)",
    "TU": "Unit tests",
    "TC": "Component tests",
    "TI": "Integration tests",
    "TE2E": "End-to-end tests",
}

# (type A, type B): every A must be linked to at least one B, in either direction.
# A rule is only enforced once at least one identifier of type B exists.
RULES = [
    ("EPIC", "JRN"),
    ("US", "EPIC"),
    ("US", "UC"),
    ("UC", "BDD"),
    ("BDD", "UC"),
    ("CP", "UC"),
    ("CP", "TE2E"),
    ("SC", "TI"),
]

_T = "|".join(sorted(TYPES, key=len, reverse=True))
TOKEN = rf"(?:{_T})-[A-Z][A-Z0-9]{{1,5}}-\d{{3}}"
ID_RX = re.compile(rf"(?<![A-Za-z0-9_-])({TOKEN})(?![A-Za-z0-9_])")
ATTR_RX = re.compile(rf"\{{({TOKEN})\}}", re.IGNORECASE)
DEF_RX = re.compile(rf"\[\[({TOKEN})(?:,[^\]]*)?\]\]|\[#({TOKEN})[\].,%]")
INCLUDE_RX = re.compile(r"^include::([^\[{]+)\[")


def expand(path: Path, seen: set[Path] | None = None):
    """Yield (source file, line number, line), following includes that stay inside the spec."""
    seen = seen or set()
    if path in seen or not path.is_file():
        return
    seen.add(path)
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        match = INCLUDE_RX.match(line)
        if match:
            target = (path.parent / match.group(1)).resolve()
            if SPEC in target.parents and "_shared" not in target.parts:
                yield from expand(target, seen)
            continue
        yield path, number, line


def clean_title(text: str, identifier: str) -> str:
    text = text.replace(identifier, " ")
    text = re.sub(r"\{[A-Za-z0-9-]+\}", " ", text)
    text = re.sub(r"\[\.[a-z-]+\]", " ", text)
    text = re.sub(r"^[\s|=.*_`:—–-]+", "", text)
    text = re.sub(r"[*_`#]", "", text)
    return text.split("|")[0].strip()[:110]


def guess_title(lines: list[tuple[Path, int, str]], index: int, end: int, identifier: str) -> str:
    title = clean_title(lines[index][2][end:], identifier)
    look = index + 1
    while not title and look < len(lines) and look <= index + 3:
        title = clean_title(lines[look][2], identifier)
        look += 1
    return title


def doc_title(doc: Path) -> str:
    for line in doc.read_text(encoding="utf-8").splitlines():
        if line.startswith("= "):
            return line[2:].strip().rsplit(": ", 1)[0]
    return doc.stem


def doc_code(doc: Path) -> str:
    return doc.stem[:5]


def main() -> int:
    docs = sorted(SPEC.glob("[0-9][0-9]-*/[0-9][0-9]-[0-9][0-9]-*.adoc"))
    defs: dict[str, dict] = {}
    errors: list[str] = []
    refs: list[tuple[str, Path, int]] = []
    edges: dict[str, set[str]] = defaultdict(set)

    for doc in docs:
        lines = list(expand(doc))
        current = None
        off = False
        for index, (source, number, line) in enumerate(lines):
            marker = line.strip()
            if marker == "// ids:off":
                off = True
            elif marker == "// ids:on":
                off = False
            if off or marker.startswith("//"):
                continue
            here = []
            for match in DEF_RX.finditer(line):
                identifier = match.group(1) or match.group(2)
                where = f"{source.relative_to(SPEC)}:{number}"
                if identifier in defs:
                    errors.append(f"DUPLICATE  {identifier} defined at {defs[identifier]['where']} and {where}")
                else:
                    defs[identifier] = {
                        "type": identifier.split("-")[0],
                        "context": identifier.split("-")[1],
                        "title": guess_title(lines, index, match.end(), identifier),
                        "doc": doc,
                        "where": where,
                    }
                current = identifier
                here.append(identifier)
            text = ATTR_RX.sub(lambda m: f" {m.group(1).upper()} ", DEF_RX.sub(" ", line))
            for match in ID_RX.finditer(text):
                identifier = match.group(1)
                if identifier in here or identifier == current:
                    continue
                refs.append((identifier, source, number))
                if current:
                    edges[current].add(identifier)

    for identifier, source, number in refs:
        if identifier not in defs:
            errors.append(f"UNDEFINED  {identifier} referenced at {source.relative_to(SPEC)}:{number}")

    incoming: dict[str, set[str]] = defaultdict(set)
    for origin, targets in edges.items():
        for target in targets:
            incoming[target].add(origin)

    def linked(identifier: str, wanted: str) -> bool:
        neighbours = edges.get(identifier, set()) | incoming.get(identifier, set())
        return any(n.startswith(wanted + "-") for n in neighbours)

    present = {d["type"] for d in defs.values()}
    for type_a, type_b in RULES:
        if type_b not in present:
            continue
        for identifier, definition in sorted(defs.items()):
            if definition["type"] == type_a and not linked(identifier, type_b):
                errors.append(f"UNTRACED   {identifier} has no link to any {type_b} ({definition['where']})")

    # --- Derived files -----------------------------------------------------
    ids_dir = GEN / "ids"
    ids_dir.mkdir(parents=True, exist_ok=True)
    expected = set()
    for doc in docs:
        out = [f"// GENERATED by _tools/ids.py: link attributes for {doc.name}. Do not edit."]
        for identifier in sorted(defs):
            target = defs[identifier]["doc"]
            path = "" if target == doc else f"../{target.parent.name}/{target.name}"
            out.append(f":{identifier.lower()}: xref:{path}#{identifier}[{identifier}]")
        destination = ids_dir / f"{doc.stem}.adoc"
        destination.write_text("\n".join(out) + "\n", encoding="utf-8")
        expected.add(destination)
    for stale in ids_dir.glob("*.adoc"):
        if stale not in expected:
            stale.unlink()

    registry = {
        identifier: {
            "type": d["type"],
            "context": d["context"],
            "title": d["title"],
            "document": str(d["doc"].relative_to(SPEC)),
            "refers_to": sorted(edges.get(identifier, ())),
            "referenced_by": sorted(incoming.get(identifier, ())),
        }
        for identifier, d in sorted(defs.items())
    }
    (GEN / "ids.json").write_text(json.dumps(registry, indent=2) + "\n", encoding="utf-8")

    out = ["// GENERATED by _tools/ids.py. Do not edit.", ""]
    out += ["== Identifier registry", ""]
    if not defs:
        out += ["No identifier has been defined yet.", ""]
    for type_code, label in TYPES.items():
        rows = [(i, d) for i, d in sorted(defs.items()) if d["type"] == type_code]
        if not rows:
            continue
        out += [f"=== {label} ({type_code})", "", '[cols="3,8,5", options="header"]', "|==="]
        out += ["| ID | Title | Defined in"]
        for identifier, d in rows:
            out.append(f"| {{{identifier}}} | {d['title']} | {doc_code(d['doc'])} {doc_title(d['doc'])}")
        out += ["|===", ""]
    out += ["== Trace links", ""]
    linked_ids = [i for i in sorted(defs) if edges.get(i) or incoming.get(i)]
    if not linked_ids:
        out += ["No trace link has been recorded yet.", ""]
    else:
        out += ['[cols="3,7,7", options="header"]', "|===", "| ID | Refers to | Referenced by"]
        for identifier in linked_ids:
            to = " ".join(f"{{{t}}}" for t in sorted(edges.get(identifier, ())) if t in defs) or "–"
            by = " ".join(f"{{{t}}}" for t in sorted(incoming.get(identifier, ()))) or "–"
            out.append(f"| {{{identifier}}} | {to} | {by}")
        out += ["|===", ""]
    (GEN / "traceability.adoc").write_text("\n".join(out), encoding="utf-8")

    # --- Report ------------------------------------------------------------
    by_type = defaultdict(int)
    for d in defs.values():
        by_type[d["type"]] += 1
    summary = ", ".join(f"{t} {by_type[t]}" for t in TYPES if by_type[t]) or "none"
    print(f"ids: {len(defs)} identifiers in {len(docs)} documents ({summary})")
    for error in errors:
        print(f"  {error}", file=sys.stderr)
    if errors:
        print(f"ids: {len(errors)} error(s)", file=sys.stderr)
        return 1
    print("ids: all references resolve, all traceability rules hold")
    return 0


if __name__ == "__main__":
    sys.exit(main())
