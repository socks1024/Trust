class_name ProfessionConfig
extends Resource
## 职业配置
##
## 定义单个职业的名称、收入范围、还款概率修正值及其专属贷款用途。
## 作为子资源嵌入 RandomApplicantConfig 中使用。

## 职业名称
@export var profession_name: String
## 职业描述（供ⓘ按钮显示）
@export_multiline var description: String = ""
## 还款概率修正值（对应文档中的职业类型修正表）
@export_range(-0.2, 0.2) var repay_modifier: float = 0.0
## 该职业专属的贷款用途（为空则仅使用通用用途池）
@export var specific_purposes: Array[LoanPurposeConfig]

## --- 收入范围 ---
## 该职业的最低年收入
@export var income_min: int = 8000
## 该职业的最高年收入
@export var income_max: int = 50000

## --- 收入回应模板 ---
## 该职业的收入对话变种，{income} 会被替换为实际数值
@export var income_responses: PackedStringArray

## --- 申请人陈述：基本信息段模板 ---
## 该职业的自我介绍模板，可用占位符：{profession} {income} {location}
@export var statement_intro_templates: PackedStringArray

## --- 可关联的资产类别 ---
## 该职业可能拥有的资产类别列表（如矿工→矿用设备，商人→店铺/飞船）
@export var associated_asset_categories: PackedStringArray
