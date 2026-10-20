extends Node2D

# 教学演示：用 _draw() 把「坐标系 + 网格」画出来
# 这样不用任何美术素材，也能看清 Godot 的二维坐标长什么样

const CELL := 32          # 一个格子的边长（像素）
const COLS := 16          # 横向格子数
const ROWS := 12          # 纵向格子数

func _draw() -> void:
	var w := COLS * CELL
	var h := ROWS * CELL
	var f := ThemeDB.fallback_font

	# 画一块底色，让网格更清楚
	draw_rect(Rect2(0, 0, w, h), Color(0.12, 0.12, 0.17))

	# 网格线：竖线 + 横线
	var line_col := Color(0.33, 0.33, 0.45)
	for c in range(COLS + 1):
		var x := float(c * CELL)
		draw_line(Vector2(x, 0), Vector2(x, h), line_col, 1)
	for r in range(ROWS + 1):
		var y := float(r * CELL)
		draw_line(Vector2(0, y), Vector2(w, y), line_col, 1)

	# 坐标轴：Godot 的原点在左上角
	# X 轴沿顶边向右，Y 轴沿左边向下
	draw_line(Vector2(0, 0), Vector2(w, 0), Color(0.9, 0.45, 0.45), 2)
	draw_line(Vector2(0, 0), Vector2(0, h), Color(0.45, 0.8, 0.5), 2)

	# 刻度文字（每隔一格标一次，免得太挤）
	var tick_col := Color(0.82, 0.82, 0.82)
	for c in range(0, COLS - 2, 2):
		draw_string(f, Vector2(c * CELL + 3, 13), str(c * CELL), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, tick_col)
	for r in range(1, ROWS - 1, 2):
		draw_string(f, Vector2(4, r * CELL + 13), str(r * CELL), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, tick_col)

	# 方向箭头
	draw_string(f, Vector2(w - 56, 16), "X →", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.9, 0.45, 0.45))
	draw_string(f, Vector2(6, h - 8), "Y ↓", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.45, 0.8, 0.5))

	# 标出精灵所在的格子：cell(3,2) 的左上角就是 (3*32, 2*32) = (96, 64)
	var cell := Vector2(3, 2)
	var pos := cell * CELL
	draw_rect(Rect2(pos, Vector2(CELL, CELL)), Color(0.95, 0.85, 0.3), false, 2)
	draw_string(f, Vector2(pos.x + CELL + 6, pos.y + 14), "cell (3,2) = (96,64)", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.95, 0.85, 0.3))
