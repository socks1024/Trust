# Gameplay 游戏玩法

## 网格关卡编辑器

### 2D 网格系统

**路径：** `content/script/gameplay/grid_system/`

**文件：** `grid_system_2d.gd`、`grid_entity_2d.gd`

**说明：** 通用的无限 2D 网格管理系统。以 Node2D 的 position 为原点，提供坐标转换、格子占用追踪、实体移动/阻挡/重叠检测等功能。网格无固定边界，可向任意方向延伸。配合 TileMapLayer 子节点（ZoneLayer + EntityLayer）实现地形数据查询和场景瓦片自动注册。

**核心功能：**
- **坐标转换** — `grid_to_world()` / `world_to_grid()`，网格坐标与世界坐标互转
- **占用追踪** — `place_entity()` / `remove_entity()` / `move_entity()`，O(1) 反向索引查表
- **碰撞系统** — 基于位掩码的 `grid_layer` / `block_mask` / `overlap_mask`，支持阻挡检测和重叠回调
- **多格实体** — `GridEntity2D.cell_size` 支持任意尺寸的实体占用
- **地形查询** — `get_cell_data()` / `get_cell_custom_data()` / `get_filtered_cells()`，读取 TileSet 的 Custom Data
- **编辑器工具** — `@tool` 模式下修改格子尺寸自动同步所有 TileMapLayer 的 TileSize

**信号：**
- `entity_placed` / `entity_removed` / `entity_moved` / `entity_blocked` / `entity_overlapped`

**GridEntity2D 虚方法（子类覆写）：**
- `_on_placed()` / `_on_removed()` / `_on_blocked()` / `_on_overlap()`