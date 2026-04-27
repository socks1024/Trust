class_name ApplicantData
extends Resource
## 贷款申请者数据
##
## 定义单个申请者的所有信息，包括个人资料、财务状况、贷款详情和申请人陈述。

## 利率挡位枚举
enum InterestRateTier {
	LOW,      ## 低利率（0~7%）
	MEDIUM,   ## 中利率（8~12%）
	HIGH,     ## 高利率（13~17%）
	USURY,    ## 高利贷（18~30%）
}

## 居住地枚举
enum ResidenceLocation {
	CENTRAL,    ## 中央区
	STARPORT,   ## 星港区
	INDUSTRIAL, ## 工业区
	MINING,     ## 矿区
	FRONTIER,   ## 边境镇
}

## 居住类型枚举
enum ResidenceType {
	OWNED,      ## 自有
	MORTGAGE,   ## 按揭
	DORMITORY,  ## 宿舍
	RENTED,     ## 租住
	BORROWED,   ## 借住
}

## 负债状态枚举
enum DebtStatus {
	REPAYING,   ## 还款中
	OVERDUE,    ## ⚠ 逾期
	SETTLED,    ## ✅ 已结清
}

## --- 个人信息 ---

@export var applicant_name: String = ""
@export var gender: String = ""
@export var age: int = 0
@export var profession: String = ""
## 职业描述（可选，留空则从 ProfessionConfig 中查找）
@export_multiline var profession_description: String = ""
@export var annual_income: int = 0

## --- 居住信息 ---

@export var residence_location: ResidenceLocation = ResidenceLocation.INDUSTRIAL
@export var residence_type: ResidenceType = ResidenceType.RENTED
## 自定义居住地名称（彩蛋角色用，留空则使用枚举名称）
@export var custom_residence_name: String = ""
## 自定义居住地描述（彩蛋角色用，留空则从配置中查找）
@export_multiline var custom_residence_description: String = ""

## --- 资产明细（0~3条） ---

@export var assets: Array[Dictionary] = []
## 资产条目格式：{"category": String, "name": String, "value": int}
## category 枚举：住房 / 交通工具 / 设备 / 存款 / 牲畜 / 店铺

## --- 负债明细（0~3条） ---

@export var debts: Array[Dictionary] = []
## 负债条目格式：{"category": String, "name": String, "amount": int, "status": DebtStatus}
## category 枚举：医疗 / 教育 / 房贷 / 消费贷 / 赌博 / 商业

## --- 贷款信息 ---

@export var loan_amount: int = 0
## 贷款用途（由策划手动填写，如"农业开发"、"飞船维修"等）
@export var loan_purpose: String = ""
@export var loan_period: int = 1
## 利率挡位（由策划根据用途手动配置）
@export var interest_rate_tier: InterestRateTier = InterestRateTier.MEDIUM

## --- 申请人陈述 ---

@export_multiline var statement: String = ""

## --- 还款概率（隐藏属性，不展示给玩家） ---

@export_range(0.0, 1.0) var repay_probability: float = 0.5

## --- 议价敏感度（影响接受度判定） ---
## 0=急需用钱型(-0.15), 1=普通型(0), 2=有底气型(+0.10), 3=必定满意, 4=必定不满
@export_enum("NeedMoney", "Normal", "Confident", "AlwaysAccept", "AlwaysReject") var bargain_sensitivity: int = 1

## --- 计算属性 ---

## 资产合计
func get_total_assets() -> int:
	var total: int = 0
	for asset: Dictionary in assets:
		total += asset.get("value", 0) as int
	return total

## 负债合计（未结清条目）
func get_total_debts() -> int:
	var total: int = 0
	for debt: Dictionary in debts:
		var status: int = debt.get("status", DebtStatus.REPAYING) as int
		if status != DebtStatus.SETTLED:
			total += debt.get("amount", 0) as int
	return total

## 净资产
func get_net_worth() -> int:
	return get_total_assets() - get_total_debts()

## 逾期条数
func get_overdue_count() -> int:
	var count: int = 0
	for debt: Dictionary in debts:
		if (debt.get("status", DebtStatus.REPAYING) as int) == DebtStatus.OVERDUE:
			count += 1
	return count

## 已结清条数
func get_settled_count() -> int:
	var count: int = 0
	for debt: Dictionary in debts:
		if (debt.get("status", DebtStatus.REPAYING) as int) == DebtStatus.SETTLED:
			count += 1
	return count

## 居住地显示名称（优先返回自定义名称）
func get_residence_location_name() -> String:
	if not custom_residence_name.is_empty():
		return custom_residence_name
	match residence_location:
		ResidenceLocation.CENTRAL:
			return "中央区"
		ResidenceLocation.STARPORT:
			return "星港区"
		ResidenceLocation.INDUSTRIAL:
			return "工业区"
		ResidenceLocation.MINING:
			return "矿区"
		ResidenceLocation.FRONTIER:
			return "边境镇"
		_:
			return "未知"

## 居住类型显示名称
func get_residence_type_name() -> String:
	match residence_type:
		ResidenceType.OWNED:
			return "自有"
		ResidenceType.MORTGAGE:
			return "按揭"
		ResidenceType.DORMITORY:
			return "宿舍"
		ResidenceType.RENTED:
			return "租住"
		ResidenceType.BORROWED:
			return "借住"
		_:
			return "未知"

## 负债状态显示名称
static func get_debt_status_name(status: DebtStatus) -> String:
	match status:
		DebtStatus.REPAYING:
			return "还款中"
		DebtStatus.OVERDUE:
			return "⚠ 逾期"
		DebtStatus.SETTLED:
			return "✅ 已结清"
		_:
			return "未知"
