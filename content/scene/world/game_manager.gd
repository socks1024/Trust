extends Node
## 游戏逻辑管理器
##
## 管理所有游戏状态和流程控制，通过引用 ReviewDesk（UI层）来更新显示。
## 挂载为 ReviewDesk 场景的子节点。

## 初始资金池
@export var initial_fund: int = 500000
## 随机申请者配置
@export var random_config: RandomApplicantConfig = null
## 每年随机申请者最少数量
@export var random_count_min: int = 3
## 每年随机申请者最多数量
@export var random_count_max: int = 6
## 殖民地税收起始金额（第1年）
@export var colony_tax_base: int = 20000
## 殖民地税收每年增量
@export var colony_tax_increment: int = 5000
## 剧情角色出场时间表（在编辑器中配置）
@export var story_schedule: StorySchedule = null

## --- 接受度计算参数 ---
@export_category("接受度计算")
## 各档位基准期望利率%（按 InterestRateTier 枚举顺序：LOW/MEDIUM/HIGH/USURY）
@export var tier_base_rates: PackedFloat32Array
## 信用修正系数下限（还款概率=1.0时，信用最好，期望利率最低）
@export var credit_modifier_min: float = 0.5
## 信用修正系数上限（还款概率=0.0时，信用最差，对高利率容忍度高）
@export var credit_modifier_max: float = 1.5
## 利率不满满值对应超出（百分点）
@export var rate_dissatisfaction_full: float = 30.0
## 利率最大不满值
@export var rate_dissatisfaction_max: float = 0.60
## 抵押最小不满值
@export var collateral_dissatisfaction_min: float = 0.0
## 抵押最大不满值
@export var collateral_dissatisfaction_max: float = 0.40
## 议价敏感度修正值：急需用钱型
@export var bargain_desperate_modifier: float = -0.15
## 议价敏感度修正值：有底气型
@export var bargain_confident_modifier: float = 0.10

## 拒绝概率上限
@export var rejection_prob_cap: float = 0.80


## UI层引用
@onready var _ui: Control = get_parent()
## 年度结算界面引用
@onready var _report: Control = %YearReport
## 教程管理器引用
@onready var _tutorial: Node = %TutorialManager

## 当前年份
var _current_year: int = 1
## 当前资金池
var _fund: int = 0
## 在贷总额
var _total_loaned: int = 0
## 当前年度的申请者列表
var _applicants: Array[ApplicantData] = []
## 当前正在审核的申请者索引
var _current_applicant_index: int = 0
## 是否正在审核中
var _is_reviewing: bool = false
## 在贷记录列表：每条记录 = {applicant, amount, interest, due_year, repay_prob}
var _active_loans: Array[Dictionary] = []
## 已出场的彩蛋角色索引集合（防止重复出场）
var _used_easter_indices: Array[int] = []

## --- 年度统计 ---
var _year_approved: int = 0
var _year_rejected: int = 0
var _year_new_loan: int = 0

## --- 累计统计（用于审核生涯） ---
var _career_total_approved: int = 0
var _career_total_interest: int = 0
var _career_total_bad_debt: int = 0


func _ready() -> void:
	_fund = initial_fund
	# 连接UI信号
	_ui.approve_pressed.connect(_on_approve)
	_ui.reject_pressed.connect(_on_reject)
	_ui.rate_changed.connect(_on_rate_changed)
	# 连接结算界面信号
	_report.next_year_pressed.connect(_on_next_year)
	_report.restart_pressed.connect(_on_restart)
	_report.back_to_menu_pressed.connect(_on_back_to_menu)

	# 延迟到所有节点ready完成后再启动，避免生命周期问题
	if random_config != null:
		_ui.set_config(random_config)
	_start_new_year.call_deferred()


## --- 流程控制 ---

## 开始新的一年
func _start_new_year() -> void:
	_year_approved = 0
	_year_rejected = 0
	_year_new_loan = 0
	_applicants = _get_applicants()
	_current_applicant_index = 0
	await _report.hide_report()
	_update_bottom_bar()
	_show_current_applicant()


## 显示当前申请者
func _show_current_applicant() -> void:
	if _current_applicant_index >= _applicants.size():
		_end_year()
		return

	var applicant: ApplicantData = _applicants[_current_applicant_index]
	_is_reviewing = true

	# 更新顶部状态栏
	_ui.update_top_bar(_current_year, _current_applicant_index + 1, _applicants.size())

	# 更新UI
	_ui.show_applicant_info(applicant)

	# 教程年前两位申请人隐藏审批条件区，第3位起显示
	var show_conditions: bool = not _tutorial.is_tutorial_year() or _current_applicant_index >= 2
	_ui.set_conditions_visible(show_conditions)

	# 计算利率信息（使用UI当前选中的利率挡位，教程年默认标准）
	_update_rate_display(applicant)

	# 教程年：面板信息更新后，显示教程弹窗再启用按钮
	if _tutorial.is_tutorial_year():
		_ui.set_buttons_enabled(false)
		# 第1年第1位申请人前额外显示开局弹窗
		if _current_year == 1 and _current_applicant_index == 0:
			_tutorial.show_intro_popup()
			await _tutorial.tutorial_step_completed
		_tutorial.show_applicant_hint(_current_applicant_index)
		await _tutorial.tutorial_step_completed

	_ui.set_buttons_enabled(true)


## 批准贷款
func _on_approve() -> void:
	if not _is_reviewing:
		return

	var applicant: ApplicantData = _applicants[_current_applicant_index]
	_is_reviewing = false

	# 使用玩家选择的利率百分比计算利息
	var rate_percent: int = _ui.get_selected_rate_percent()
	var base_rate: float = float(rate_percent) / 100.0
	var period_multiplier: float = 1.0 + (applicant.loan_period - 1) * 0.1
	var actual_rate: float = base_rate * period_multiplier
	var total_interest: int = int(applicant.loan_amount * actual_rate * applicant.loan_period)

	# 获取玩家勾选的抵押物
	var collaterals: Array[Dictionary] = _ui.get_selected_collaterals()
	var collateral_value: int = _ui.get_selected_collateral_value()

	# 计算拒绝概率并掷骰判定
	var rejection_prob: float = _calc_rejection_probability(applicant, rate_percent, collateral_value)
	var roll: float = randf()
	CLog.o("接受度判定：%s，利率：%d%%，抵押估值：%d，拒绝概率：%.2f，掷骰：%.2f" % [
		applicant.applicant_name, rate_percent, collateral_value, rejection_prob, roll,
	])

	if roll < rejection_prob:
		# 申请者拒绝了贷款条件
		CLog.o("申请者 %s 拒绝了贷款条件" % applicant.applicant_name)
		_ui.set_buttons_enabled(false)
		_ui.show_dialogue("[color=#ffaa33]申请者认为条件不合适，拒绝了贷款。[/color]")
		await get_tree().create_timer(1.0).timeout
		_next_applicant()
		return

	# 申请者接受了条件，正式批准
	_fund -= applicant.loan_amount
	_total_loaned += applicant.loan_amount
	_year_approved += 1
	_year_new_loan += applicant.loan_amount
	_career_total_approved += 1

	_active_loans.append({
		"applicant": applicant,
		"amount": applicant.loan_amount,
		"interest": total_interest,
		"due_year": _current_year + applicant.loan_period - 1,
		"repay_prob": applicant.repay_probability,
		"collaterals": collaterals,
		"collateral_value": collateral_value,
	})
	CLog.o("批准贷款：%s，金额：%d，利率：%d%%，抵押物估值：%d，到期年份：%d" % [
		applicant.applicant_name, applicant.loan_amount, rate_percent,
		collateral_value, _current_year + applicant.loan_period - 1,
	])

	_ui.set_buttons_enabled(false)
	_ui.show_dialogue("[color=#5ee8e8]贷款已批准。[/color]")
	_update_bottom_bar()

	await get_tree().create_timer(1.0).timeout
	_next_applicant()


## 拒绝贷款
func _on_reject() -> void:
	if not _is_reviewing:
		return
	_is_reviewing = false
	_year_rejected += 1

	var applicant: ApplicantData = _applicants[_current_applicant_index]
	CLog.o("拒绝贷款：%s" % applicant.applicant_name)

	_ui.set_buttons_enabled(false)
	_ui.show_dialogue("[color=#ff6b6b]贷款已拒绝。[/color]")

	await get_tree().create_timer(1.0).timeout
	_next_applicant()


## 进入下一位申请者
func _next_applicant() -> void:
	_current_applicant_index += 1
	_show_current_applicant()


## 结束当前年度
func _end_year() -> void:
	_is_reviewing = false
	_ui.set_buttons_enabled(false)
	CLog.o("第 %d 年结束，开始回收贷款" % _current_year)

	# 回收本年到期的贷款
	var year_interest_income: int = 0
	var total_defaulted_amount: int = 0
	var remaining_loans: Array[Dictionary] = []
	## 详细列表：按时还款
	var repaid_details: Array[Dictionary] = []
	## 详细列表：逾期未还
	var defaulted_details: Array[Dictionary] = []
	## 到期贷款的遍历序号（用于结算界面交错显示）
	var _due_order: int = 0

	for loan: Dictionary in _active_loans:
		if loan["due_year"] <= _current_year:
			# 到期了，根据还款概率判定
			var roll: float = randf()
			if roll <= loan["repay_prob"]:
				# 成功还款：本金 + 利息
				var repayment: int = loan["amount"] + loan["interest"]
				_fund += repayment
				_total_loaned -= loan["amount"]
				year_interest_income += loan["interest"]
				_career_total_interest += loan["interest"]
				repaid_details.append({
					"name": loan["applicant"].applicant_name,
					"purpose": loan["applicant"].loan_purpose,
					"amount": loan["amount"],
					"interest": loan["interest"],
					"repayment": repayment,
					"_order": _due_order,
				})
				_due_order += 1
				CLog.o("贷款回收成功：%s，回收 %d" % [loan["applicant"].applicant_name, repayment])
			else:
				# 违约：损失 = 本金 - 抵押物估值
				var col_value: int = loan.get("collateral_value", 0) as int
				var actual_loss: int = maxi(loan["amount"] - col_value, 0)
				_total_loaned -= loan["amount"]
				total_defaulted_amount += actual_loss
				_career_total_bad_debt += actual_loss
				# 有抵押物时回收部分资金
				if col_value > 0:
					_fund += mini(col_value, loan["amount"])
				defaulted_details.append({
					"name": loan["applicant"].applicant_name,
					"purpose": loan["applicant"].loan_purpose,
					"amount": loan["amount"],
					"collateral_value": col_value,
					"actual_loss": actual_loss,
					"_order": _due_order,
				})
				_due_order += 1
				CLog.o("贷款违约：%s，本金 %d，抵押回收 %d，实际损失 %d" % [
					loan["applicant"].applicant_name, loan["amount"], col_value, actual_loss,
				])
		else:
			# 未到期，保留
			remaining_loans.append(loan)

	_active_loans = remaining_loans
	_update_bottom_bar()

	## 详细列表：仍在还款期（按到期年份排序）
	var ongoing_details: Array[Dictionary] = []
	for loan: Dictionary in _active_loans:
		ongoing_details.append({
			"name": loan["applicant"].applicant_name,
			"purpose": loan["applicant"].loan_purpose,
			"amount": loan["amount"],
			"due_year": loan["due_year"],
		})
	ongoing_details.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["due_year"] < b["due_year"])

	CLog.o("年度结算：回收 %d 笔，违约 %d 笔，资金池 %d" % [repaid_details.size(), defaulted_details.size(), _fund])

	# 填充结算界面静态数据
	_report.set_title(_current_year)
	_report.show_approval_stats(_year_approved, _year_rejected, _year_new_loan)

	# 扣除殖民地税收（逐年递增）
	var tax_paid: int = colony_tax_base + colony_tax_increment * (_current_year - 1)
	_fund -= tax_paid
	var total_profit: int = _fund + _total_loaned - initial_fund
	var profit_percent: int = int(float(total_profit) / float(initial_fund) * 100.0)

	# 预填资金变动和生涯统计（揭晓动画期间玩家可以看到其他区域）
	_report.show_fund_change(year_interest_income, total_defaulted_amount, tax_paid, total_profit, profit_percent)

	# 判定游戏状态并显示对应按钮
	if _fund < 0:
		_report.show_career_stats(
			_current_year, _career_total_approved,
			_career_total_interest, _career_total_bad_debt,
			"信用中心资金池归零，殖民地被迫废弃……"
		)
		_report.set_button_mode("game_over")
	elif _check_victory(profit_percent):
		_report.show_career_stats(
			_current_year, _career_total_approved,
			_career_total_interest, _career_total_bad_debt,
			"利润突破 +20%%，殖民地经济蓬勃发展！"
		)
		_report.set_button_mode("victory")
	else:
		_report.show_career_stats(
			_current_year, _career_total_approved,
			_career_total_interest, _career_total_bad_debt
		)
		_report.set_button_mode("normal")

	# 显示结算界面
	_report.hide_fund_and_career()
	await _report.show_report()

	# 教程年：界面显示后弹出结算介绍弹窗
	if _tutorial.is_tutorial_year():
		_tutorial.show_report_popup()
		await _tutorial.tutorial_step_completed

	# 播放逐条揭晓动画（界面已可见）
	await _report.show_repayment_stats(repaid_details, ongoing_details, defaulted_details)

	# 揭晓完成后显示资金变动和审核生涯
	await _report.reveal_fund_and_career()


## 检查是否通关（利润达到 +20%）
func _check_victory(profit_percent: int) -> bool:
	return profit_percent >= 20


## --- 结算界面回调 ---

## 进入下一年
func _on_next_year() -> void:
	_current_year += 1
	# 第1年结束后关闭教程
	if _tutorial.is_tutorial_year():
		_tutorial.end_tutorial()
	_start_new_year()


## 重新开始
func _on_restart() -> void:
	_ui.restart_requested.emit()


## 返回主菜单
func _on_back_to_menu() -> void:
	_ui.back_to_menu_requested.emit()


## --- 辅助方法 ---

## 更新底部状态栏
func _update_bottom_bar() -> void:
	var total_profit: int = _fund + _total_loaned - initial_fund
	var profit_percent: int = int(float(total_profit) / float(initial_fund) * 100.0)
	_ui.update_bottom_bar(_fund, _total_loaned, total_profit, profit_percent)


## 更新利率显示（根据当前选中的利率百分比重新计算）
func _update_rate_display(applicant: ApplicantData) -> void:
	var rate_percent: int = _ui.get_selected_rate_percent()
	var base_rate: float = float(rate_percent) / 100.0
	var period_multiplier: float = 1.0 + (applicant.loan_period - 1) * 0.1
	var actual_rate: float = base_rate * period_multiplier
	var total_interest: int = int(applicant.loan_amount * actual_rate * applicant.loan_period)
	var total_repayment: int = applicant.loan_amount + total_interest
	_ui.show_rate_info(
		"%d%%（基础 %d%% × %.1f）" % [int(actual_rate * 100), rate_percent, period_multiplier],
		total_interest,
		total_repayment,
	)


## 计算申请者拒绝概率
func _calc_rejection_probability(applicant: ApplicantData, rate_percent: int, collateral_value: int) -> float:
	# 1. 利率不满值（期望利率 = 档位基准利率 × 信用修正系数）
	var tier_idx: int = applicant.interest_rate_tier as int
	var base_rate: float = tier_base_rates[clampi(tier_idx, 0, tier_base_rates.size() - 1)]
	
	# 信用修正系数：还款概率越高，信用越好，期望利率越低
	var credit_modifier: float = lerpf(credit_modifier_max, credit_modifier_min, clampf(applicant.repay_probability, 0.0, 1.0))
	var expected_rate: float = base_rate * credit_modifier
	var rate_excess: float = maxf(float(rate_percent) - expected_rate, 0.0)
	var rate_dissatisfaction: float = clampf(rate_excess / rate_dissatisfaction_full, 0.0, 1.0) * rate_dissatisfaction_max

	# 2. 抵押不满值
	var collateral_dissatisfaction: float = 0.0
	if collateral_value > 0:
		var coverage: float = float(collateral_value) / maxf(float(applicant.loan_amount), 1.0)
		collateral_dissatisfaction = lerpf(collateral_dissatisfaction_min, collateral_dissatisfaction_max, clampf(coverage, 0.0, 1.0))

	# 3. 个体修正（议价敏感度）
	# 3=必定满意 → 直接返回0；4=必定不满 → 直接返回1
	if applicant.bargain_sensitivity == 3:
		CLog.o("拒绝概率明细：必定满意（bargain_sensitivity=3）→ 0.00")
		return 0.0
	if applicant.bargain_sensitivity == 4:
		CLog.o("拒绝概率明细：必定不满（bargain_sensitivity=4）→ 1.00")
		return 1.0

	var bargain_modifier: float = 0.0
	match applicant.bargain_sensitivity:
		0:
			bargain_modifier = bargain_desperate_modifier
		2:
			bargain_modifier = bargain_confident_modifier

	var rejection: float = clampf(rate_dissatisfaction + collateral_dissatisfaction + bargain_modifier, 0.0, rejection_prob_cap)
	CLog.o("拒绝概率明细：利率不满=%.2f（期望%.1f%%，实际%d%%），抵押不满=%.2f（估值%d），个体修正=%.2f → 总计=%.2f" % [
		rate_dissatisfaction, expected_rate, rate_percent,
		collateral_dissatisfaction, collateral_value,
		bargain_modifier, rejection,
	])
	return rejection


## 利率滑动条变化回调
func _on_rate_changed(_rate_percent: int) -> void:
	if _current_applicant_index < _applicants.size():
		_update_rate_display(_applicants[_current_applicant_index])


## 获取当前年度的申请者列表
func _get_applicants() -> Array[ApplicantData]:
	# 教程年使用固定教学申请人（不打乱顺序）
	if _tutorial.is_tutorial_year():
		return _tutorial.get_tutorial_applicants()
	var result: Array[ApplicantData] = []
	# 30%几率从彩蛋角色池中随机抽取1个未出场的角色
	if story_schedule != null and _used_easter_indices.size() < story_schedule.characters.size():
		if randf() < 0.3:
			var available: Array[int] = []
			for i: int in range(story_schedule.characters.size()):
				if i not in _used_easter_indices:
					available.append(i)
			if not available.is_empty():
				var pick: int = available[randi() % available.size()]
				_used_easter_indices.append(pick)
				result.append(story_schedule.characters[pick])
	# 生成随机路人
	if random_config != null:
		var count: int = randi_range(random_count_min, random_count_max)
		for i: int in range(count):
			result.append(random_config.generate_applicant())
	result.shuffle()
	return result
