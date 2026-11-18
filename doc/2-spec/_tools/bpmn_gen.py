#!/usr/bin/env python3
"""Text-first BPMN 2.0.

Turns each process description (NN-folder/bpmn/BPMN-CTX-NNN.toml) into a real BPMN 2.0
file with diagram interchange, laid out on a grid: one horizontal lane per participant,
one column per step. The result opens in Camunda Modeler or bpmn.io for manual touch-ups.

Output: doc/9-generated/bpmn/BPMN-CTX-NNN.bpmn (derived, safe to delete).

Description format (TOML):

    id = "BPMN-ORD-001"
    name = "Order placement"
    pool = "Alten Commerce Platform"
    lanes = [ { id = "customer", name = "Customer" }, ... ]
    nodes = [ { id = "start", type = "startEvent", lane = "customer", col = 0, name = "…" }, ... ]
    flows = [ { from = "start", to = "cart", name = "" }, ... ]

Node types: startEvent, endEvent, task, userTask, serviceTask, sendTask, receiveTask,
manualTask, exclusiveGateway, parallelGateway, eventBasedGateway, intermediateCatchEvent,
intermediateThrowEvent. Optional node keys: event = "message" | "timer" | "error" |
"compensate" | "terminate", row = 0..n (stack several nodes in one lane cell).
Optional flow keys: name, exit = "right" | "top" | "bottom", enter = "left" | "top" | "bottom".
"""

from __future__ import annotations

import sys
import tomllib
from pathlib import Path
from xml.sax.saxutils import quoteattr

SPEC = Path(__file__).resolve().parent.parent
OUT = SPEC.parent / "9-generated" / "bpmn"

POOL_LABEL = 30
LANE_LABEL = 30
MARGIN_X = 15
COL_WIDTH = 175
ROW_HEIGHT = 120
LANE_PADDING = 20

SIZES = {"event": (36, 36), "gateway": (50, 50), "task": (120, 80)}
EVENT_DEFINITIONS = {
    "message": "messageEventDefinition",
    "timer": "timerEventDefinition",
    "error": "errorEventDefinition",
    "compensate": "compensateEventDefinition",
    "terminate": "terminateEventDefinition",
}


def kind(node_type: str) -> str:
    if node_type.endswith("Event"):
        return "event"
    if node_type.endswith("Gateway"):
        return "gateway"
    return "task"


def build(source: Path) -> str:
    spec = tomllib.loads(source.read_text(encoding="utf-8"))
    lanes = spec["lanes"]
    nodes = {n["id"]: n for n in spec["nodes"]}
    flows = spec["flows"]

    rows = {lane["id"]: 1 + max((n.get("row", 0) for n in nodes.values() if n["lane"] == lane["id"]), default=0)
            for lane in lanes}
    columns = 1 + max(n["col"] for n in nodes.values())
    width = POOL_LABEL + LANE_LABEL + 2 * MARGIN_X + columns * COL_WIDTH

    lane_box = {}
    y = 0
    for lane in lanes:
        height = rows[lane["id"]] * ROW_HEIGHT + 2 * LANE_PADDING
        lane_box[lane["id"]] = (POOL_LABEL, y, width - POOL_LABEL, height)
        y += height
    pool_height = y

    box = {}
    for node in nodes.values():
        w, h = SIZES[kind(node["type"])]
        _, lane_y, _, _ = lane_box[node["lane"]]
        cx = POOL_LABEL + LANE_LABEL + MARGIN_X + node["col"] * COL_WIDTH + COL_WIDTH / 2
        cy = lane_y + LANE_PADDING + node.get("row", 0) * ROW_HEIGHT + ROW_HEIGHT / 2
        box[node["id"]] = (cx - w / 2, cy - h / 2, w, h)

    def port(node_id: str, side: str) -> tuple[float, float]:
        x, y_, w, h = box[node_id]
        return {
            "left": (x, y_ + h / 2),
            "right": (x + w, y_ + h / 2),
            "top": (x + w / 2, y_),
            "bottom": (x + w / 2, y_ + h),
        }[side]

    def blocked(a: str, b: str) -> bool:
        """True when another node sits between a and b on the same lane row."""
        na, nb = nodes[a], nodes[b]
        if na["lane"] != nb["lane"] or na.get("row", 0) != nb.get("row", 0):
            return False
        low, high = sorted((na["col"], nb["col"]))
        return any(n["lane"] == na["lane"] and n.get("row", 0) == na.get("row", 0) and low < n["col"] < high
                   for n in nodes.values())

    def route(flow: dict) -> list[tuple[float, float]]:
        a, b = flow["from"], flow["to"]
        acx = box[a][0] + box[a][2] / 2
        acy = box[a][1] + box[a][3] / 2
        bcy = box[b][1] + box[b][3] / 2
        forward = nodes[b]["col"] > nodes[a]["col"]
        exit_side, enter_side = flow.get("exit"), flow.get("enter")
        if not exit_side and not enter_side:
            if nodes[a]["col"] == nodes[b]["col"]:
                exit_side, enter_side = ("bottom", "top") if bcy > acy else ("top", "bottom")
            elif forward and not blocked(a, b):
                exit_side, enter_side = "right", "left"
            else:
                # Backward flow, or forward flow that would cross a node:
                # travel in the free band at the edge of the target lane.
                _, lane_y, _, lane_height = lane_box[nodes[b]["lane"]]
                side, channel = ("top", lane_y + 10) if bcy <= acy else ("bottom", lane_y + lane_height - 10)
                start, end = port(a, side), port(b, side)
                return [start, (start[0], channel), (end[0], channel), end]
        exit_side, enter_side = exit_side or "right", enter_side or "left"
        start, end = port(a, exit_side), port(b, enter_side)
        vertical_exit, vertical_enter = exit_side in ("top", "bottom"), enter_side in ("top", "bottom")
        points = [start]
        if vertical_exit and vertical_enter:
            if abs(start[0] - end[0]) > 1:
                mid = (start[1] + end[1]) / 2
                points += [(start[0], mid), (end[0], mid)]
        elif vertical_exit:
            points.append((start[0], end[1]))
        elif vertical_enter:
            points.append((end[0], start[1]))
        elif abs(start[1] - end[1]) > 1:
            mid = acx + COL_WIDTH / 2
            points += [(mid, start[1]), (mid, end[1])]
        points.append(end)
        return points

    q = quoteattr
    pid = "Process_" + spec["id"].replace("-", "_")
    x = ['<?xml version="1.0" encoding="UTF-8"?>',
         '<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"'
         ' xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"'
         ' xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"'
         ' xmlns:di="http://www.omg.org/spec/DD/20100524/DI"'
         f' id={q("Definitions_" + spec["id"])} targetNamespace="http://alten-commerce-platform/bpmn">',
         '  <bpmn:collaboration id="Collaboration">',
         f'    <bpmn:participant id="Pool" name={q(spec.get("pool", spec["name"]))} processRef={q(pid)} />',
         '  </bpmn:collaboration>',
         f'  <bpmn:process id={q(pid)} name={q(spec["name"])} isExecutable="false">',
         '    <bpmn:laneSet id="LaneSet">']
    for lane in lanes:
        x.append(f'      <bpmn:lane id={q("Lane_" + lane["id"])} name={q(lane["name"])}>')
        x += [f'        <bpmn:flowNodeRef>{n["id"]}</bpmn:flowNodeRef>' for n in nodes.values() if n["lane"] == lane["id"]]
        x.append('      </bpmn:lane>')
    x.append('    </bpmn:laneSet>')
    for node in nodes.values():
        x.append(f'    <bpmn:{node["type"]} id={q(node["id"])} name={q(node.get("name", ""))}>')
        x += [f'      <bpmn:incoming>Flow_{i}</bpmn:incoming>' for i, f in enumerate(flows) if f["to"] == node["id"]]
        x += [f'      <bpmn:outgoing>Flow_{i}</bpmn:outgoing>' for i, f in enumerate(flows) if f["from"] == node["id"]]
        if node.get("event"):
            x.append(f'      <bpmn:{EVENT_DEFINITIONS[node["event"]]} id={q("Def_" + node["id"])} />')
        x.append(f'    </bpmn:{node["type"]}>')
    for i, flow in enumerate(flows):
        x.append(f'    <bpmn:sequenceFlow id="Flow_{i}" name={q(flow.get("name", ""))}'
                 f' sourceRef={q(flow["from"])} targetRef={q(flow["to"])} />')
    x += ['  </bpmn:process>',
          '  <bpmndi:BPMNDiagram id="Diagram">',
          '    <bpmndi:BPMNPlane id="Plane" bpmnElement="Collaboration">',
          '      <bpmndi:BPMNShape id="Pool_di" bpmnElement="Pool" isHorizontal="true">',
          f'        <dc:Bounds x="0" y="0" width="{width}" height="{pool_height}" />',
          '      </bpmndi:BPMNShape>']
    for lane in lanes:
        lx, ly, lw, lh = lane_box[lane["id"]]
        x += [f'      <bpmndi:BPMNShape id={q("Lane_" + lane["id"] + "_di")} bpmnElement={q("Lane_" + lane["id"])} isHorizontal="true">',
              f'        <dc:Bounds x="{lx}" y="{ly}" width="{lw}" height="{lh}" />',
              '      </bpmndi:BPMNShape>']
    for node in nodes.values():
        nx, ny, nw, nh = box[node["id"]]
        marker = ' isMarkerVisible="true"' if node["type"] == "exclusiveGateway" else ""
        x.append(f'      <bpmndi:BPMNShape id={q(node["id"] + "_di")} bpmnElement={q(node["id"])}{marker}>')
        x.append(f'        <dc:Bounds x="{nx:.0f}" y="{ny:.0f}" width="{nw}" height="{nh}" />')
        if kind(node["type"]) != "task" and node.get("name"):
            x += ['        <bpmndi:BPMNLabel>',
                  f'          <dc:Bounds x="{nx + nw / 2 - 55:.0f}" y="{ny + nh + 4:.0f}" width="110" height="28" />',
                  '        </bpmndi:BPMNLabel>']
        x.append('      </bpmndi:BPMNShape>')
    for i, flow in enumerate(flows):
        points = route(flow)
        x.append(f'      <bpmndi:BPMNEdge id="Flow_{i}_di" bpmnElement="Flow_{i}">')
        x += [f'        <di:waypoint x="{px:.0f}" y="{py:.0f}" />' for px, py in points]
        if flow.get("name"):
            lx, ly = points[0]
            label_width = 7 * len(flow["name"]) + 8
            x += ['        <bpmndi:BPMNLabel>',
                  f'          <dc:Bounds x="{lx + 6:.0f}" y="{ly - 19:.0f}" width="{label_width}" height="14" />',
                  '        </bpmndi:BPMNLabel>']
        x.append('      </bpmndi:BPMNEdge>')
    x += ['    </bpmndi:BPMNPlane>', '  </bpmndi:BPMNDiagram>', '</bpmn:definitions>', '']
    return "\n".join(x)


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    sources = sorted(SPEC.glob("[0-9][0-9]-*/bpmn/BPMN-*.toml"))
    expected = set()
    for source in sources:
        target = OUT / f"{source.stem}.bpmn"
        target.write_text(build(source), encoding="utf-8")
        expected.add(target)
    for stale in OUT.glob("*.bpmn"):
        if stale not in expected:
            stale.unlink()
    print(f"bpmn: {len(sources)} process(es) written to {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
