class_name RandomApplicantConfig
extends Resource
## 随机申请者生成配置
##
## 定义用于随机生成申请者的素材池和数值范围。
## 策划可在编辑器中配置所有随机参数。

## --- 姓名素材池 ---
@export_category("通用信息")
## 男性名池
@export var first_names_male: PackedStringArray
## 女性名池
@export var first_names_female: PackedStringArray
## 姓氏池
@export var last_names: PackedStringArray
## 年龄范围
@export var age_min: int = 18
@export var age_max: int = 60

## --- 职业素材池 ---
@export_category("职业")
@export var professions: Array[ProfessionConfig]

## --- 通用贷款用途素材池 ---
@export_category("通用贷款用途")
## 所有职业都可能出现的贷款用途
@export var loan_purposes: Array[LoanPurposeConfig]

## --- 资产模板池 ---
@export_category("资产模板")
## 通用资产模板（存款、住房等，不受职业限制）
@export var general_assets: Array[AssetTemplateConfig]
## 职业专属资产在 ProfessionConfig.associated_asset_categories 中定义

## --- 负债模板池 ---
@export_category("负债模板")
## 无负债的概率
@export_range(0.0, 1.0) var no_debt_chance: float = 0.3
## 负债模板配置列表
@export var debt_templates: Array[DebtTemplateConfig]

## --- 居住地修正 ---
@export_category("居住地")
## 各居住地的还款概率修正值（按枚举顺序：中央区/星港区/工业区/矿区/边境镇）
@export var residence_location_modifiers: PackedFloat32Array = PackedFloat32Array([0.03, 0.01, 0.0, -0.01, -0.03])
## 各居住地的描述（按枚举顺序，供ⓘ按钮显示）
@export var residence_location_descriptions: PackedStringArray

## --- 居住类型修正 ---
@export_category("居住类型")
## 各居住类型的还款概率修正值（按枚举顺序：自有/按揭/宿舍/租住/借住）
@export var residence_type_modifiers: PackedFloat32Array = PackedFloat32Array([0.03, 0.01, 0.0, -0.01, -0.03])
## 各居住类型的描述（按枚举顺序，供ⓘ按钮显示）
@export var residence_type_descriptions: PackedStringArray

## --- 申请人陈述模板（结构化四段式） ---
@export_category("申请人陈述")

## 居住地自我介绍模板池（按枚举顺序：中央区/星港区/工业区/矿区/边境镇）
## 可用占位符：{profession} {income} {location}
@export var statement_location_templates: Array[PackedStringArray]

## 财务状况段模板池——良好（净资产 > 贷款金额 × 0.5）
## 可用占位符：{assets} {debts}
@export var statement_finance_good_templates: PackedStringArray
## 财务状况段模板池——一般（净资产在 0 ~ 贷款金额 × 0.5 之间）
@export var statement_finance_normal_templates: PackedStringArray
## 财务状况段模板池——较差（净资产 < 0）
@export var statement_finance_poor_templates: PackedStringArray

## 议价敏感度段模板池——急需用钱型（-0.15）
@export var statement_bargain_desperate_templates: PackedStringArray
## 议价敏感度段模板池——普通型（0）
@export var statement_bargain_normal_templates: PackedStringArray
## 议价敏感度段模板池——有底气型（+0.10）
@export var statement_bargain_confident_templates: PackedStringArray

## --- 还款概率计算参数 ---
@export_category("还款概率计算参数")
## 基础还款概率
@export_range(0.0, 1.0) var base_repay_prob: float = 0.5
## 随机扰动范围
@export_range(0.0, 0.1) var random_noise: float = 0.03

@export_group("DTI（总债务负担比）")
## DTI 下限
@export var dti_lower: float = 1.0
## DTI 上限
@export var dti_upper: float = 8.0
## DTI 最大加分
@export var dti_max_bonus: float = 0.10
## DTI 最大扣分
@export var dti_max_penalty: float = -0.20

@export_group("净资产比")
## 净资产比下限
@export var nw_lower: float = -1.0
## 净资产比上限
@export var nw_upper: float = 1.5
## 净资产比最大扣分
@export var nw_max_penalty: float = -0.10
## 净资产比最大加分
@export var nw_max_bonus: float = 0.10

@export_group("收入水平")
## 收入下限
@export var income_lower: float = 0.0
## 收入上限
@export var income_upper: float = 80000.0
## 收入最大扣分
@export var income_max_penalty: float = -0.10
## 收入最大加分
@export var income_max_bonus: float = 0.10

@export_group("负债状态")
## 无负债加分
@export var no_debt_bonus: float = 0.05
## 有已结清记录且无逾期加分
@export var has_settled_bonus: float = 0.10
## 1条逾期扣分
@export var one_overdue_penalty: float = -0.10
## 2条及以上逾期扣分
@export var multi_overdue_penalty: float = -0.20


## --- 生成方法 ---

## 生成一个随机申请者
## 生成顺序：职业→收入→资产→居住类型→负债→贷款用途→陈述→还款概率
## 每一步只依赖前面已确定的数据，避免逻辑矛盾
func generate_applicant() -> ApplicantData:
	var data: ApplicantData = ApplicantData.new()

	# 1. 随机性别（50/50）
	var is_male: bool = randf() < 0.5
	data.gender = "男" if is_male else "女"

	# 2. 随机姓名 = 名 + "·" + 姓
	var first_pool: PackedStringArray = first_names_male if is_male else first_names_female
	data.applicant_name = first_pool[randi() % first_pool.size()] + "·" + last_names[randi() % last_names.size()]

	# 3. 随机基础属性
	data.age = randi_range(age_min, age_max)

	# 4. 随机职业 → 决定收入
	var profession_entry: ProfessionConfig = professions[randi() % professions.size()]
	data.profession = profession_entry.profession_name
	data.annual_income = _snap_to_thousand(randi_range(profession_entry.income_min, profession_entry.income_max))

	# 5. 无业且收入为0时，限制资产为空
	var is_unemployed_no_income: bool = (data.annual_income == 0 and profession_entry.profession_name == "无业")

	# 6. 随机资产（受职业过滤）
	if is_unemployed_no_income:
		data.assets = []
	else:
		data.assets = _generate_assets(profession_entry)

	# 7. 根据资产决定居住类型（有住房→自有/按揭，无住房→宿舍/租住/借住）
	data.residence_location = randi() % 5 as ApplicantData.ResidenceLocation
	data.residence_type = _determine_residence_type(data.assets)

	# 8. 随机负债（受居住类型约束）
	data.debts = _generate_debts(data)

	# 9. 随机用途（受职业+资产+居住状态过滤）
	var purpose_entry: LoanPurposeConfig = _pick_loan_purpose(profession_entry, data)
	data.loan_purpose = purpose_entry.purpose_name
	data.interest_rate_tier = purpose_entry.tier

	# 10. 根据用途配置的范围生成贷款金额和周期
	data.loan_amount = _snap_to_thousand(randi_range(purpose_entry.loan_amount_min, purpose_entry.loan_amount_max))
	data.loan_period = randi_range(purpose_entry.loan_period_min, purpose_entry.loan_period_max)

	# 11. 随机议价敏感度
	data.bargain_sensitivity = _pick_bargain_sensitivity()

	# 12. 生成申请人陈述（结构化四段式拼接）
	data.statement = _generate_structured_statement(data, profession_entry)

	# 13. 计算还款概率
	data.repay_probability = _calc_repay_probability(data, profession_entry)

	CLog.o("生成随机申请者：%s，职业：%s，收入：%d，资产：%d，负债：%d，贷款：%d，还款概率：%.2f" % [
		data.applicant_name, data.profession, data.annual_income,
		data.get_total_assets(), data.get_total_debts(),
		data.loan_amount, data.repay_probability,
	])

	return data


## 计算随机申请者的还款概率（8因素线性修正）
func _calc_repay_probability(data: ApplicantData, prof: ProfessionConfig) -> float:
	var prob: float = base_repay_prob

	# 因素1：负债状态
	var overdue_count: int = data.get_overdue_count()
	if data.debts.is_empty():
		prob += no_debt_bonus
	elif overdue_count >= 2:
		prob += multi_overdue_penalty
	elif overdue_count == 1:
		prob += one_overdue_penalty
	elif data.get_settled_count() > 0:
		# 有已结清记录且无逾期 → 正面信号
		prob += has_settled_bonus

	# 因素2：DTI（总债务负担比）
	var total_debt: float = float(data.get_total_debts() + data.loan_amount)
	var annual: float = maxf(float(data.annual_income), 1.0)
	var dti: float = total_debt / annual
	var dti_t: float = clampf((dti - dti_lower) / maxf(dti_upper - dti_lower, 0.01), 0.0, 1.0)
	prob += lerpf(dti_max_bonus, dti_max_penalty, dti_t)

	# 因素3：净资产比
	var net_worth: float = float(data.get_net_worth())
	var nw_ratio: float = net_worth / maxf(float(data.loan_amount), 1.0)
	var nw_t: float = clampf((nw_ratio - nw_lower) / maxf(nw_upper - nw_lower, 0.01), 0.0, 1.0)
	prob += lerpf(nw_max_penalty, nw_max_bonus, nw_t)

	# 因素4：收入水平
	var inc_t: float = clampf((float(data.annual_income) - income_lower) / maxf(income_upper - income_lower, 0.01), 0.0, 1.0)
	prob += lerpf(income_max_penalty, income_max_bonus, inc_t)

	# 因素5：职业类型
	prob += prof.repay_modifier

	# 因素6：居住地
	var loc_idx: int = data.residence_location as int
	if loc_idx >= 0 and loc_idx < residence_location_modifiers.size():
		prob += residence_location_modifiers[loc_idx]

	# 因素7：居住类型
	var type_idx: int = data.residence_type as int
	if type_idx >= 0 and type_idx < residence_type_modifiers.size():
		prob += residence_type_modifiers[type_idx]

	# 随机扰动
	prob += randf_range(-random_noise, random_noise)

	return clampf(prob, 0.05, 0.95)


## --- 私有辅助方法 ---

## 根据资产中是否有住房来决定居住类型
func _determine_residence_type(assets: Array[Dictionary]) -> ApplicantData.ResidenceType:
	var has_housing: bool = false
	for asset: Dictionary in assets:
		if asset.get("category", "") == "住房":
			has_housing = true
			break

	if has_housing:
		# 有住房资产 → 自有(60%) 或 按揭(40%)
		if randf() < 0.6:
			return ApplicantData.ResidenceType.OWNED
		return ApplicantData.ResidenceType.MORTGAGE

	# 无住房资产 → 宿舍/租住/借住
	var roll: float = randf()
	if roll < 0.30:
		return ApplicantData.ResidenceType.DORMITORY
	elif roll < 0.75:
		return ApplicantData.ResidenceType.RENTED
	return ApplicantData.ResidenceType.BORROWED


## 生成资产列表（0~3条，受职业过滤）
func _generate_assets(prof: ProfessionConfig) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var asset_count: int = randi_range(0, 3)
	if asset_count == 0:
		return result

	# 构建候选资产池：通用资产中只保留职业允许的类别
	var allowed_categories: PackedStringArray = prof.associated_asset_categories
	var candidate_pool: Array[AssetTemplateConfig] = []
	for tpl: AssetTemplateConfig in general_assets:
		# 住房和存款是通用资产，所有职业都可以拥有
		if tpl.is_housing or tpl.category == "存款":
			candidate_pool.append(tpl)
		# 其他资产需要职业关联
		elif not allowed_categories.is_empty() and allowed_categories.has(tpl.category):
			candidate_pool.append(tpl)

	# 从候选池中随机抽取
	while result.size() < asset_count and not candidate_pool.is_empty():
		var idx: int = randi() % candidate_pool.size()
		var tpl: AssetTemplateConfig = candidate_pool[idx]
		result.append({
			"category": tpl.category,
			"name": tpl.display_name,
			"value": _snap_to_thousand(randi_range(tpl.value_min, tpl.value_max)),
		})
		candidate_pool.remove_at(idx)

	return result


## 生成负债列表（0~3条，受居住类型约束）
func _generate_debts(data: ApplicantData) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	# 按揭居住类型必须有房贷负债
	var is_mortgage: bool = (data.residence_type == ApplicantData.ResidenceType.MORTGAGE)
	if is_mortgage:
		var mortgage_amount: int = _snap_to_thousand(int(float(data.annual_income) * randf_range(0.5, 1.5)))
		if mortgage_amount > 0:
			result.append({
				"category": "房贷",
				"name": "房贷",
				"amount": mortgage_amount,
				"status": ApplicantData.DebtStatus.REPAYING as int,
			})

	if randf() < no_debt_chance or debt_templates.is_empty():
		return result

	var debt_count: int = randi_range(1, 3)
	# 构建可用负债模板池（排除不合理的负债）
	var available: Array[DebtTemplateConfig] = []
	for tpl: DebtTemplateConfig in debt_templates:
		# 自有住房或非按揭 → 排除房贷（按揭的房贷已在上面添加）
		if tpl.category == "房贷":
			continue
		# 无业者排除商业贷款
		if tpl.category == "商业" and data.annual_income == 0:
			continue
		available.append(tpl)

	for i: int in range(debt_count):
		if available.is_empty():
			break
		var idx: int = randi() % available.size()
		var tpl: DebtTemplateConfig = available[idx]
		available.remove_at(idx)

		var debt_ratio: float = randf_range(tpl.debt_ratio_min, tpl.debt_ratio_max)
		var amount: int = _snap_to_thousand(int(float(data.annual_income) * debt_ratio))
		if amount <= 0:
			continue

		# 决定负债状态
		var status: ApplicantData.DebtStatus = ApplicantData.DebtStatus.REPAYING
		if randf() < tpl.overdue_chance:
			status = ApplicantData.DebtStatus.OVERDUE
		elif randf() < tpl.settled_chance:
			status = ApplicantData.DebtStatus.SETTLED

		result.append({
			"category": tpl.category,
			"name": tpl.display_name,
			"amount": amount,
			"status": status as int,
		})

	return result


## 选择贷款用途（受职业+资产+居住状态过滤）
func _pick_loan_purpose(prof: ProfessionConfig, data: ApplicantData) -> LoanPurposeConfig:
	# 合并职业专属用途和通用用途
	var all_purposes: Array[LoanPurposeConfig] = []
	if not prof.specific_purposes.is_empty():
		all_purposes = prof.specific_purposes + loan_purposes
	else:
		all_purposes.assign(loan_purposes)

	# 检查申请者状态
	var has_housing: bool = false
	var has_shop: bool = false
	for asset: Dictionary in data.assets:
		var cat: String = asset.get("category", "")
		if cat == "住房":
			has_housing = true
		if cat == "店铺":
			has_shop = true

	var is_owner: bool = (
		data.residence_type == ApplicantData.ResidenceType.OWNED
		or data.residence_type == ApplicantData.ResidenceType.MORTGAGE
	)

	# 过滤不合理的用途
	var filtered: Array[LoanPurposeConfig] = []
	for purpose: LoanPurposeConfig in all_purposes:
		# 已有住房（自有/按揭）→ 排除"住房建设"
		if purpose.purpose_name == "住房建设" and (has_housing or is_owner):
			continue
		# 没有店铺资产 → 排除"商铺扩张"
		if purpose.purpose_name == "商铺扩张" and not has_shop:
			continue
		filtered.append(purpose)

	# 兜底：如果全被过滤掉了，回退到通用用途池
	if filtered.is_empty():
		filtered.assign(loan_purposes)
		# 再次过滤住房建设
		if has_housing or is_owner:
			var fallback: Array[LoanPurposeConfig] = []
			for p: LoanPurposeConfig in filtered:
				if p.purpose_name != "住房建设":
					fallback.append(p)
			if not fallback.is_empty():
				filtered = fallback

	return filtered[randi() % filtered.size()]


## 随机选择议价敏感度（0=急需用钱, 1=普通, 2=有底气）
func _pick_bargain_sensitivity() -> int:
	var roll: float = randf()
	if roll < 0.25:
		return 0  # 急需用钱型
	elif roll < 0.75:
		return 1  # 普通型
	return 2  # 有底气型


## 生成结构化四段式申请人陈述
func _generate_structured_statement(data: ApplicantData, prof: ProfessionConfig) -> String:
	# 1. 基本信息段：将职业模板池和居住地模板池合并，随机选一条
	var intro_segment: String = _pick_intro_segment(data, prof)

	# 2. 财务状况段：根据净资产/贷款金额比分档
	var finance_segment: String = _pick_finance_segment(data)

	# 3. 贷款用途段：从该用途的 responses 中随机选一条
	var purpose_segment: String = _pick_purpose_segment(data)

	# 4. 议价敏感度段：根据 bargain_sensitivity 选择对应池
	var bargain_segment: String = _pick_bargain_segment(data)

	# 后三段随机打乱顺序，基本信息段固定在开头
	var parts: Array[String] = [finance_segment, purpose_segment, bargain_segment]
	parts.shuffle()
	parts.insert(0, intro_segment)
	var result: String = "\n\n".join(parts)

	# 替换所有占位符
	result = result.replace("{profession}", data.profession)
	result = result.replace("{income}", _format_number(data.annual_income))
	result = result.replace("{location}", data.get_residence_location_name())
	result = result.replace("{assets}", _format_number(data.get_total_assets()))
	result = result.replace("{debts}", _format_number(data.get_total_debts()))
	result = result.replace("{purpose}", data.loan_purpose)
	result = result.replace("{amount}", _format_number(data.loan_amount))
	result = result.replace("{period}", str(data.loan_period) + "年")
	
	# 去掉可能多余的引号
	result = result.replace("\"", "")

	return result


## 选取基本信息段模板
func _pick_intro_segment(data: ApplicantData, prof: ProfessionConfig) -> String:
	var pool: PackedStringArray = PackedStringArray()

	# 合并职业模板池
	if not prof.statement_intro_templates.is_empty():
		pool.append_array(prof.statement_intro_templates)

	# 合并居住地模板池
	var loc_idx: int = data.residence_location as int
	if loc_idx >= 0 and loc_idx < statement_location_templates.size():
		var loc_pool: PackedStringArray = statement_location_templates[loc_idx]
		if not loc_pool.is_empty():
			pool.append_array(loc_pool)

	if pool.is_empty():
		return "我是%s。" % data.profession
	return pool[randi() % pool.size()]


## 选取财务状况段模板
func _pick_finance_segment(data: ApplicantData) -> String:
	var net_worth: float = float(data.get_net_worth())
	var loan: float = maxf(float(data.loan_amount), 1.0)
	var ratio: float = net_worth / loan

	var pool: PackedStringArray
	if ratio > 0.5:
		pool = statement_finance_good_templates
	elif net_worth >= 0:
		pool = statement_finance_normal_templates
	else:
		pool = statement_finance_poor_templates

	if pool.is_empty():
		return ""
	return pool[randi() % pool.size()]


## 选取贷款用途段模板
func _pick_purpose_segment(data: ApplicantData) -> String:
	# 从所有用途配置中找到匹配的用途，使用其 responses
	var all_purposes: Array[LoanPurposeConfig] = []
	for prof: ProfessionConfig in professions:
		all_purposes.append_array(prof.specific_purposes)
	all_purposes.append_array(loan_purposes)

	for purpose: LoanPurposeConfig in all_purposes:
		if purpose.purpose_name == data.loan_purpose and not purpose.responses.is_empty():
			return purpose.responses[randi() % purpose.responses.size()]

	return "这笔贷款用于%s。" % data.loan_purpose


## 选取议价敏感度段模板
func _pick_bargain_segment(data: ApplicantData) -> String:
	var pool: PackedStringArray
	match data.bargain_sensitivity:
		0:  # 急需用钱型
			pool = statement_bargain_desperate_templates
		1:  # 普通型
			pool = statement_bargain_normal_templates
		2:  # 有底气型
			pool = statement_bargain_confident_templates
		_:
			pool = statement_bargain_normal_templates

	if pool.is_empty():
		return ""
	return pool[randi() % pool.size()]


## 格式化数字（添加千位分隔符）
func _format_number(value: int) -> String:
	var s: String = str(value)
	var result: String = ""
	var count: int = 0
	for i: int in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result


## 将数值取整到千位
func _snap_to_thousand(value: int) -> int:
	return int(roundf(float(value) / 1000.0)) * 1000
