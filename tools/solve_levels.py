#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Boxman 关卡求解器：批量验证 levels_txt/ 全部关卡可通关。

算法：A*（按推箱次数），状态 = (箱子集合, 玩家可达域规范化键)；
剪枝：死格（逆向拉 BFS 求不可达目标的格子）+ 2x2 冻结死锁；
启发：每箱到最近目标的最小推距之和（箱子数多于目标数时取最小的 |goals| 项，保持可采纳）。

输出逐关状态：solved / unsolvable / timeout，超时如实标注，不冒充通过。
"""
import os
import sys
import time
import heapq
from multiprocessing import Pool, cpu_count

BASE = os.path.dirname(os.path.abspath(__file__))
LEVEL_DIR = os.path.normpath(os.path.join(BASE, "..", "levels_txt"))
TIME_LIMIT = float(os.environ.get("SOLVE_LIMIT", "60"))  # 每关秒数，可用环境变量覆盖
DIRS = ((0, -1), (0, 1), (-1, 0), (1, 0))


def parse_level(path):
    walls, goals, boxes, player = set(), set(), set(), None
    with open(path, encoding="utf-8") as f:
        rows = []
        ox = oy = 0
        for line in f:
            line = line.rstrip("\n")
            if line.startswith(";"):
                s = line[line.find("(") + 1:line.rfind(")")]
                a, b = s.split(",")
                ox, oy = int(a), int(b)
            else:
                rows.append(line)
        while rows and not rows[-1].strip():
            rows.pop()
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                x, y = ox + i, oy + j
                if ch == "#":
                    walls.add((x, y))
                elif ch == ".":
                    goals.add((x, y))
                elif ch == "$":
                    boxes.add((x, y))
                elif ch == "*":
                    boxes.add((x, y))
                    goals.add((x, y))
                elif ch == "@":
                    player = (x, y)
                elif ch == "+":
                    player = (x, y)
                    goals.add((x, y))
    if player is None:
        raise ValueError("缺少玩家")
    return walls, goals, frozenset(boxes), player


def flood_floors(walls, player):
    """从玩家洪泛出可达地面（限制在地图包围盒内），返回 frozenset。"""
    xs = [p[0] for p in walls]
    ys = [p[1] for p in walls]
    minx, maxx, miny, maxy = min(xs), max(xs), min(ys), max(ys)
    seen = {player}
    stack = [player]
    while stack:
        x, y = stack.pop()
        for dx, dy in DIRS:
            q = (x + dx, y + dy)
            if (minx <= q[0] <= maxx and miny <= q[1] <= maxy
                    and q not in walls and q not in seen):
                seen.add(q)
                stack.append(q)
    return frozenset(seen)


def live_and_dist(floors, goals):
    """逆向拉 BFS：返回 (live 格子集合, 每格到最近目标的最小推距表)。
    拉规则：箱子从 c 被拉到 c+d，需玩家站 c+d、退到 c+2d，即 c+d 与 c+2d 均为地面。"""
    dist = {}
    queue = []
    for g in goals:
        if g in floors:
            dist[g] = 0
            queue.append(g)
    head = 0
    while head < len(queue):
        c = queue[head]
        head += 1
        for dx, dy in DIRS:
            # 反向推：箱子在 c，从 c 来的方向是 -d，即前驱 p = (c.x-dx, c.y-dy)
            p = (c[0] - dx, c[1] - dy)
            pp = (c[0] - 2 * dx, c[1] - 2 * dy)
            if p in floors and pp in floors and p not in dist:
                dist[p] = dist[c] + 1
                queue.append(p)
    return frozenset(dist.keys()), dist


def reachable_cells(floors, boxes, start):
    seen = {start}
    stack = [start]
    while stack:
        x, y = stack.pop()
        for dx, dy in DIRS:
            q = (x + dx, y + dy)
            if q in floors and q not in boxes and q not in seen:
                seen.add(q)
                stack.append(q)
    return seen


def frozen_2x2(boxes, goals, cell):
    """cell 周围 4 个 2x2 方块若全为墙/箱且含非目标箱，则判定冻结死锁。"""
    x, y = cell
    for ax, ay in ((0, 0), (-1, 0), (0, -1), (-1, -1)):
        block = [(x + ax, y + ay), (x + ax + 1, y + ay),
                 (x + ax, y + ay + 1), (x + ax + 1, y + ay + 1)]
        if all((p in boxes or p in WALLS_REF) for p in block):
            if any(p in boxes and p not in goals for p in block):
                return True
    return False


def solve_level(name):
    """单关卡求解，返回 (name, status, detail)。status: solved/unsolvable/timeout/error"""
    t0 = time.time()
    try:
        walls, goals, boxes0, player0 = parse_level(os.path.join(LEVEL_DIR, name))
        globals()['WALLS_REF'] = walls  # frozen_2x2 引用（单进程内安全）
        floors = flood_floors(walls, player0)
        live, dist = live_and_dist(floors, goals)

        for b in boxes0:
            if b not in live:
                return (name, "unsolvable", "初始箱子位于死格 %s" % (b,))

        goal_set = goals
        n_goal = len(goal_set)

        def h(boxes):
            ds = sorted(dist[b] for b in boxes)
            return sum(ds[:n_goal])

        start_key = (boxes0, min(reachable_cells(floors, boxes0, player0)))
        best = {start_key: 0}
        heap = [(h(boxes0), 0, 0, boxes0, player0)]
        counter = 1
        expansions = 0

        while heap:
            if expansions % 512 == 0 and time.time() - t0 > TIME_LIMIT:
                return (name, "timeout", "超过 %.0fs，扩展 %d 状态" % (TIME_LIMIT, expansions))
            f, g, _, boxes, player = heapq.heappop(heap)
            key = (boxes, min(reachable_cells(floors, boxes, player)))
            if best.get(key, 1 << 60) < g:
                continue
            expansions += 1
            if goal_set <= boxes:
                return (name, "solved", "推 %d 步，扩展 %d 状态，耗时 %.1fs" % (g, expansions, time.time() - t0))
            reach = reachable_cells(floors, boxes, player)
            for b in boxes:
                for dx, dy in DIRS:
                    player_side = (b[0] - dx, b[1] - dy)
                    target = (b[0] + dx, b[1] + dy)
                    if player_side not in reach:
                        continue
                    if target not in floors or target in boxes or target not in live:
                        continue
                    nb = frozenset((boxes - {b}) | {target})
                    if frozen_2x2(nb, goal_set, target):
                        continue
                    ng = g + 1
                    nkey = (nb, min(reachable_cells(floors, nb, b)))
                    if best.get(nkey, 1 << 60) <= ng:
                        continue
                    best[nkey] = ng
                    heapq.heappush(heap, (ng + h(nb), ng, counter, nb, b))
                    counter += 1
        return (name, "unsolvable", "搜索空间穷尽（扩展 %d）" % expansions)
    except Exception as e:  # noqa
        return (name, "error", repr(e))


def main():
    # 可选命令行参数：只验证指定的关卡文件（如 python3 solve_levels.py Level006.txt ...）
    requested = [a if a.endswith(".txt") else a + ".txt" for a in sys.argv[1:]]
    all_names = sorted(f for f in os.listdir(LEVEL_DIR)
                       if f.startswith("Level") and f.endswith(".txt"))
    names = [n for n in all_names if not requested or n in requested]
    print("待验证关卡: %d" % len(names))
    t0 = time.time()
    workers = min(6, cpu_count() or 1)
    results = {"solved": [], "unsolvable": [], "timeout": [], "error": []}
    with Pool(workers) as pool:
        for name, status, detail in pool.imap_unordered(solve_level, names, chunksize=1):
            results[status].append((name, detail))
            mark = {"solved": "✓", "unsolvable": "✗", "timeout": "⏱", "error": "!"}[status]
            print("[%s] %-16s %s" % (mark, name.replace(".txt", ""), detail), flush=True)

    print("\n========== 汇总 ==========")
    for status in ("solved", "unsolvable", "timeout", "error"):
        print("%s: %d" % (status, len(results[status])))
        for name, detail in sorted(results[status]):
            if status != "solved":
                print("   %s: %s" % (name, detail))
    print("总耗时: %.1fs（%d 进程并行）" % (time.time() - t0, workers))
    return 0 if len(results["solved"]) == len(names) else 1


if __name__ == "__main__":
    sys.exit(main())
