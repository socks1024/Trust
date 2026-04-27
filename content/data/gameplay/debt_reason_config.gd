class_name DebtTemplateConfig
extends Resource
## 负债模板配置
##
## 定义用于随机生成负债条目的模板。
## 作为子资源嵌入 RandomApplicantConfig 中使用。

## 负债类别（医疗 / 教育 / 房贷 / 消费贷 / 赌博 / 商业）
@export var category: String = ""
## 显示名称（如"医疗欠款"、"赌场借贷"）
@export var display_name: String = ""
## 负债类别描述（供ⓘ按钮显示）
@export_multiline var description: String = ""
## 该负债的最小金额/收入比
@export_range(0.0, 3.0) var debt_ratio_min: float = 0.1
## 该负债的最大金额/收入比
@export_range(0.0, 3.0) var debt_ratio_max: float = 0.5
## 逾期概率（0~1，生成时按此概率决定是否逾期）
@export_range(0.0, 1.0) var overdue_chance: float = 0.1
## 已结清概率（0~1，未逾期时按此概率决定是否已结清）
@export_range(0.0, 1.0) var settled_chance: float = 0.1
