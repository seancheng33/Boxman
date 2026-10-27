#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Boxman 关卡反解析工具（离线，只读 tscn，不改运行时）

功能：
1. 解析 level/LevelNNN.tscn，提取墙(TileMap 实例)、箱(box)、目标(dest)、玩家(play) 的网格坐标；
2. 生成标准 sokoban ASCII 文本（#@$*. + 空格）到 levels_txt/；
3. 逐关把 ASCII 回读成坐标集合并与 tscn 原始集合比对，验证无损；
4. 输出汇总报告。

Godot 3 TileMap format=1 的 tile_data 每 3 个 int 一组：[cell_index, src_tile, flags]；
cell_index 低 16 位是有符号 x，高 16 位是有符号 y。
"""

import os
import re
import sys
from collections import namedtuple

PROJECT = "E:/godot/Boxman"
LEVEL_DIR = os.path.join(PROJECT, "level")
OUT_DIR = os.path.join(PROJECT, "levels_txt")
TILE = 64

Cell = namedtuple("Cell", ["node", "parent", "props"])


def parse_tscn(path):
    """极简 tscn 解析：返回 (ext_map, nodes)；ext_map: id(str)->res path。"""
    ext_map = {}
    nodes = []
    cur = None
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        for raw in f:
            line = raw.rstrip("\n")
            m = re.match(r'\[ext_resource path="([^"]+)" type="[^"]+" id=(\d+)\]', line)
            if m:
                ext_map[m.group(2)] = m.group(1)
                continue
            if line.startswith("[node"):
                name = re.search(r'name="([^"]+)"', line)
                parent = re.search(r'parent="([^"]+)"', line)
                inst = re.search(r'instance=ExtResource\( ?(\d+) ?\)', line)
                ntype = re.search(r'type="([^"]+)"', line)
                cur = Cell(
                    name.group(1) if name else "",
                    parent.group(1) if parent else "",
                    {"_instance": ext_map.get(inst.group(1)) if inst else None,
                     "_type": ntype.group(1) if ntype else None},
                )
                nodes.append(cur)
                continue
            if cur is not None and "=" in line and not line.startswith("["):
                key, _, val = line.partition("=")
                cur.props[key.strip()] = val.strip()
    return ext_map, nodes


def parse_vec2(s):
    m = re.match(r'Vector2\( ?(-?[\d.]+), ?(-?[\d.]+) ?\)', s or "")
    if not m:
        return None
    return float(m.group(1)), float(m.group(2))


def parse_pool_int_array(s):
    m = re.search(r'PoolIntArray\( ?(.*?) ?\)', s or "", re.S)
    if not m:
        return []
    return [int(x) for x in m.group(1).replace("\n", " ").split(",") if x.strip()]


def decode_cell_index(v):
    x = v & 0xFFFF
    if x >= 0x8000:
        x -= 0x10000
    y = v >> 16
    if y >= 0x8000:
        y -= 0x10000
    return x, y


def pixel_to_grid(p, offset=(0.0, 0.0), warnings=None, what=""):
    gx = (p[0] + offset[0]) / TILE
    gy = (p[1] + offset[1]) / TILE
    rx, ry = round(gx), round(gy)
    if abs(gx - rx) > 1e-6 or abs(gy - ry) > 1e-6:
        # 原关卡存在 8~24px 的非对齐实体，游戏内靠 Area2D 重叠容差运行；
        # 反解析时吸附到最近格子，并记录警告。
        msg = "%s 坐标 %s 非对齐(偏差 %.1fpx)，吸附到 (%d,%d)" % (
            what, p, max(abs(gx - rx), abs(gy - ry)) * TILE, rx, ry)
        if warnings is not None:
            warnings.append(msg)
        else:
            raise ValueError(msg)
    return int(rx), int(ry)


def parse_level(path, warnings=None):
    """返回 dict: walls/dests/boxes (set of (x,y)), player (x,y)"""
    _, nodes = parse_tscn(path)
    walls, dests, boxes = set(), set(), set()
    player = None

    for n in nodes:
        inst = n.props.get("_instance") or ""
        pos = parse_vec2(n.props.get("position"))
        if inst.endswith("TileMap.tscn"):
            offset = pos or (0.0, 0.0)
            data = parse_pool_int_array(n.props.get("tile_data"))
            for i in range(0, len(data) - 2, 3):
                cx, cy = decode_cell_index(data[i])
                src = data[i + 1]
                if src == 0:  # 目前 TileSet 只定义了 0 号墙砖
                    gx, gy = pixel_to_grid((cx * TILE, cy * TILE), offset, warnings, "墙")
                    walls.add((gx, gy))
                else:
                    raise ValueError("未知 tile id: %s" % src)
        elif inst.endswith("dest.tscn"):
            if pos:
                dests.add(pixel_to_grid(pos, warnings=warnings, what="目标"))
        elif inst.endswith("box.tscn"):
            if pos:
                boxes.add(pixel_to_grid(pos, warnings=warnings, what="箱子"))
        elif inst.endswith("play.tscn"):
            if pos:
                if player is not None:
                    raise ValueError("出现多个玩家")
                player = pixel_to_grid(pos, warnings=warnings, what="玩家")

    if player is None:
        raise ValueError("缺少玩家")
    return {"walls": walls, "dests": dests, "boxes": boxes, "player": player}


def render_ascii(level):
    """渲染 ASCII；返回 (text, origin)，origin 为渲染区左上角的网格坐标。"""
    pts = set(level["walls"]) | set(level["dests"]) | set(level["boxes"]) | {level["player"]}
    minx = min(p[0] for p in pts) - 1
    maxx = max(p[0] for p in pts) + 1
    miny = min(p[1] for p in pts) - 1
    maxy = max(p[1] for p in pts) + 1

    rows = []
    for y in range(miny, maxy + 1):
        row = []
        for x in range(minx, maxx + 1):
            ch = " "
            if (x, y) in level["walls"]:
                ch = "#"
            if (x, y) in level["dests"]:
                ch = "."
            if (x, y) in level["boxes"]:
                ch = "*" if (x, y) in level["dests"] else "$"
            if (x, y) == level["player"]:
                ch = "+" if (x, y) in level["dests"] else "@"
            row.append(ch)
        rows.append("".join(row))
    return "\n".join(rows) + "\n", (minx, miny)


def parse_ascii(text, origin):
    """ASCII -> 坐标集合（带 origin 还原真实网格坐标）。"""
    walls, dests, boxes, players = set(), set(), set(), []
    ox, oy = origin
    for j, line in enumerate(text.rstrip("\n").split("\n")):
        for i, ch in enumerate(line):
            x, y = ox + i, oy + j
            if ch == "#":
                walls.add((x, y))
            elif ch == ".":
                dests.add((x, y))
            elif ch == "$":
                boxes.add((x, y))
            elif ch == "*":
                boxes.add((x, y)); dests.add((x, y))
            elif ch == "@":
                players.append((x, y))
            elif ch == "+":
                players.append((x, y)); dests.add((x, y))
            elif ch == " ":
                pass
            else:
                raise ValueError("非法字符: %r" % ch)
    if len(players) != 1:
        raise ValueError("玩家数量 != 1: %d" % len(players))
    return {"walls": walls, "dests": dests, "boxes": boxes, "player": players[0]}


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    files = sorted(f for f in os.listdir(LEVEL_DIR) if f.endswith(".tscn"))
    print("共发现关卡文件: %d" % len(files))

    ok, failed = 0, []
    warn_log = {}
    print("%-14s %5s %5s %5s %5s" % ("关卡", "墙", "箱", "目标", "校验"))
    for fname in files:
        path = os.path.join(LEVEL_DIR, fname)
        try:
            warnings = []
            lv = parse_level(path, warnings)
            # 健全性：箱子数少于目标数才致命（无解）；推箱子允许多余箱子
            if len(lv["boxes"]) < len(lv["dests"]):
                raise ValueError("箱子(%d) < 目标(%d)，无解" % (len(lv["boxes"]), len(lv["dests"])))
            text, origin = render_ascii(lv)
            # 回读比对（无损验证核心）
            back = parse_ascii(text, origin)
            if back != lv:
                diff = [k for k in lv if lv[k] != back[k]]
                raise ValueError("回读不一致: %s" % diff)
            # 落盘
            out_name = os.path.splitext(fname)[0] + ".txt"
            with open(os.path.join(OUT_DIR, out_name), "w", encoding="utf-8") as f:
                f.write("; origin=(%d,%d)\n" % origin)
                f.write(text)
            ok += 1
            if warnings:
                warn_log[fname] = warnings
            print("%-14s %5d %5d %5d %5s" % (
                os.path.splitext(fname)[0], len(lv["walls"]),
                len(lv["boxes"]), len(lv["dests"]),
                "OK!" if warnings else "OK"))
        except Exception as e:
            failed.append((fname, str(e)))
            print("%-14s %5s %5s %5s %5s  <-- %s" % (
                os.path.splitext(fname)[0], "-", "-", "-", "FAIL", e))

    print("\n========== 汇总 ==========")
    print("成功: %d / %d" % (ok, len(files)))
    print("失败: %d" % len(failed))
    for fname, err in failed:
        print("  %s: %s" % (fname, err))
    print("带吸附警告的关卡数: %d" % len(warn_log))
    for fname, ws in warn_log.items():
        for w in ws:
            print("  %s: %s" % (fname, w))
    return 0 if not failed else 1


if __name__ == "__main__":
    sys.exit(main())
