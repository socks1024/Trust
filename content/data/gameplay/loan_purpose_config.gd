class_name LoanPurposeConfig
extends Resource
## 贷款用途配置
##
## 定义单个贷款用途的名称、利率挡位和对话回应。
## 作为子资源嵌入 RandomApplicantConfig 中使用。

## 用途名称
@export var purpose_name: String
## 利率挡位
@export var tier: ApplicantData.InterestRateTier = ApplicantData.InterestRateTier.MEDIUM
## 申请者关于用途的对话回应（随机抽取一条）
@export var responses: PackedStringArray

## --- 贷款金额范围 ---
## 该用途的最小贷款金额
@export var loan_amount_min: int = 5000
## 该用途的最大贷款金额
@export var loan_amount_max: int = 100000

## --- 贷款周期范围（年） ---
## 该用途的最短贷款周期
@export var loan_period_min: int = 1
## 该用途的最长贷款周期
@export var loan_period_max: int = 6
