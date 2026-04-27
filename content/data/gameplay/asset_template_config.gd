class_name AssetTemplateConfig
extends Resource
## 资产模板配置
##
## 定义用于随机生成资产条目的模板。
## 作为子资源嵌入 RandomApplicantConfig 中使用。

## 资产类别（住房 / 交通工具 / 设备 / 存款 / 牲畜 / 店铺）
@export var category: String = ""
## 显示名称（如"自有住房"、"货运飞船"）
@export var display_name: String = ""
## 资产类别描述（供ⓘ按钮显示）
@export_multiline var description: String = ""
## 最小估值
@export var value_min: int = 5000
## 最大估值
@export var value_max: int = 50000
## 是否为住房类资产（用于居住类型约束）
@export var is_housing: bool = false
