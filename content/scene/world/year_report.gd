extends Control
## 年度结算界面 - 纯UI层
##
## 只负责显示年度报告和用户交互，不包含任何游戏逻辑。
## 通过信号通知外部用户的操作，通过公开方法接收外部数据并更新显示。

## --- 用户操作信号 ---

## 玩家点击了"进入下一年"按钮
signal next_year_pressed
## 玩家点击了"重新开始"按钮
signal restart_pressed
## 玩家点击了"返回主菜单"按钮
signal back_to_menu_pressed

## --- 音效事件 ---
## 还款成功音效
@export var repaid_sfx: AudioEvent
## 逾期违约音效
@export var defaulted_sfx: AudioEvent

## --- 揭晓动画配置 ---
## 每条贷款揭晓前的悬念等待时间（秒）
@export var reveal_suspense_delay: float = 0.6
## 每条贷款揭晓后的停留时间（秒）
@export var reveal_result_delay: float = 0.4
## 震动幅度（像素）
@export var shake_amplitude: float = 8.0
## 震动次数
@export var shake_count: int = 4
## 震动总时长（秒）
@export var shake_duration: float = 0.3

## --- 标题 ---
@onready var title_label: Label = %TitleLabel

## --- 审批统计 ---
@onready var approved_label: Label = %ApprovedLabel
@onready var rejected_label: Label = %RejectedLabel
@onready var new_loan_label: Label = %NewLoanLabel

## --- 还款情况 ---
@onready var repaid_vbox: VBoxContainer = %RepaidVBox
@onready var ongoing_vbox: VBoxContainer = %OngoingVBox
@onready var defaulted_vbox: VBoxContainer = %DefaultedVBox

## --- 资金变动 ---
@onready var fund_title: Label = %FundTitle
@onready var interest_income_label: Label = %InterestIncomeLabel
@onready var bad_debt_label: Label = %BadDebtLabel
@onready var colony_tax_label: Label = %ColonyTaxLabel
@onready var fund_change_label: Label = %FundChangeLabel
@onready var fund_sep: HSeparator = %FundSep

## --- 审核生涯 ---
@onready var career_title: Label = %CareerTitle
@onready var career_vbox: VBoxContainer = %CareerVBox
@onready var button_sep: HSeparator = %ButtonSep

## --- 操作按钮 ---
@onready var next_year_btn: CommonButton = %NextYearBtn
@onready var restart_btn: CommonButton = %RestartBtn
@onready var back_to_menu_btn: CommonButton = %BackToMenuBtn

## --- 音效播放器 ---
@onready var _sfx_player: AudioEventPlayer = %SfxPlayer

## 动画时长
var _show_duration: float = 0.3
var _hide_duration: float = 0.2
## 当前活跃的 Tween（用于打断旧动画）
var _tween: Tween = null
## 是否正在播放揭晓动画
var _is_revealing: bool = false


func _ready() -> void:
	next_year_btn.pressed.connect(next_year_pressed.emit)
	restart_btn.pressed.connect(restart_pressed.emit)
	back_to_menu_btn.pressed.connect(back_to_menu_pressed.emit)
	hide()


## --- 供外部调用的显示方法 ---

## 显示年度报告标题
func set_title(year: int) -> void:
	title_label.text = "📊 第 %d 年 年度报告" % year


## 显示审批统计
func show_approval_stats(approved: int, rejected: int, new_loan_amount: int) -> void:
	approved_label.text = "本年批准贷款：%d 笔" % approved
	rejected_label.text = "拒绝：%d 笔" % rejected
	new_loan_label.text = "新增放贷：%s" % _format_currency(new_loan_amount)


## 显示还款情况（异步逐条揭晓动画）
func show_repayment_stats(repaid_list: Array[Dictionary], ongoing_list: Array[Dictionary], defaulted_list: Array[Dictionary]) -> void:
	_is_revealing = true

	# --- 合并到期贷款列表（还款 + 违约），按原始遍历顺序交错揭晓 ---
	var due_loans: Array[Dictionary] = []
	for item: Dictionary in repaid_list:
		var entry: Dictionary = item.duplicate()
		entry["_result"] = "repaid"
		due_loans.append(entry)
	for item: Dictionary in defaulted_list:
		var entry: Dictionary = item.duplicate()
		entry["_result"] = "defaulted"
		due_loans.append(entry)
	# 按原始遍历顺序排序，实现还款与违约交错揭晓
	due_loans.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["_order"] < b["_order"])

	# --- 到期贷款揭晓区域（使用 RepaidVBox 作为容器） ---
	if due_loans.size() > 0:
		_add_detail_line(repaid_vbox, "── 本年到期贷款结算 ──")
		# 逐条揭晓
		for loan: Dictionary in due_loans:
			if not _is_revealing:
				break
			# 先显示悬念行：借款人 + 本金
			var pending_text: String = "    %s | %s | 本金 %s  ⏳ 判定中..." % [
				loan["name"], loan["purpose"], _format_currency(loan["amount"]),
			]
			var pending_label: Label = _add_detail_line(repaid_vbox, pending_text)
			pending_label.modulate.a = 0.0
			# 淡入悬念行
			var fade_tween: Tween = create_tween()
			fade_tween.tween_property(pending_label, "modulate:a", 1.0, 0.2)
			await fade_tween.finished
			# 悬念等待
			await get_tree().create_timer(reveal_suspense_delay).timeout
			# 揭晓结果
			if loan["_result"] == "repaid":
				pending_label.text = "    ✅ %s | %s | 本金 %s + 利息 %s = 回收 %s" % [
					loan["name"], loan["purpose"],
					_format_currency(loan["amount"]),
					_format_currency(loan["interest"]),
					_format_currency(loan["repayment"]),
				]
				pending_label.add_theme_color_override("font_color", Color("5ee8e8"))
				# 播放成功音效
				if repaid_sfx:
					_sfx_player.play_audio(repaid_sfx)
			else:
				var col_val: int = loan.get("collateral_value", 0) as int
				var actual_loss: int = loan.get("actual_loss", loan["amount"]) as int
				if col_val > 0:
					pending_label.text = "    ❌ %s | %s | 本金 %s - 抵押回收 %s = 损失 %s" % [
						loan["name"], loan["purpose"],
						_format_currency(loan["amount"]),
						_format_currency(mini(col_val, loan["amount"])),
						_format_currency(actual_loss),
					]
				else:
					pending_label.text = "    ❌ %s | %s | 损失 %s" % [
						loan["name"], loan["purpose"],
						_format_currency(actual_loss),
					]
				pending_label.add_theme_color_override("font_color", Color("ff6b6b"))
				# 播放违约音效
				if defaulted_sfx:
					_sfx_player.play_audio(defaulted_sfx)
				# 震动效果
				_shake_label(pending_label)
			# 结果停留
			await get_tree().create_timer(reveal_result_delay).timeout

		# 汇总行
		var total_repaid: int = 0
		var total_defaulted: int = 0
		for loan: Dictionary in due_loans:
			if loan["_result"] == "repaid":
				total_repaid += loan["repayment"]
			else:
				total_defaulted += loan.get("actual_loss", loan["amount"]) as int
		if total_repaid > 0:
			var repaid_summary: Label = _add_detail_line(repaid_vbox, "    本年回收：+%s（%d 笔）" % [_format_currency(total_repaid), repaid_list.size()])
			repaid_summary.add_theme_color_override("font_color", Color("5ee8e8"))
		if total_defaulted > 0:
			var defaulted_summary: Label = _add_detail_line(repaid_vbox, "    本年损失：-%s（%d 笔）" % [_format_currency(total_defaulted), defaulted_list.size()])
			defaulted_summary.add_theme_color_override("font_color", Color("ff6b6b"))
	else:
		_add_detail_line(repaid_vbox, "── 本年无到期贷款 ──")

	# --- 仍在还款期（折叠到 OngoingVBox，不抢戏） ---
	if ongoing_list.size() > 0:
		_add_detail_line(ongoing_vbox, "⏳ 仍在还款期：%d 笔" % ongoing_list.size())
		for item: Dictionary in ongoing_list:
			var line: Label = _add_detail_line(ongoing_vbox, "    %s | %s | 本金 %s，到期第 %d 年" % [
				item["name"], item["purpose"], _format_currency(item["amount"]), item["due_year"],
			])
			line.modulate.a = 0.6
	else:
		_add_detail_line(ongoing_vbox, "⏳ 仍在还款期：0 笔")

	_is_revealing = false


## 显示资金变动
func show_fund_change(interest_income: int, bad_debt_loss: int, colony_tax: int, total_profit: int, profit_percent: int) -> void:
	interest_income_label.text = "利息收入：+%s" % _format_currency(interest_income)
	bad_debt_label.text = "坏账损失：-%s" % _format_currency(bad_debt_loss)
	colony_tax_label.text = "殖民地税收：-%s" % _format_currency(colony_tax)
	var sign: String = "+" if total_profit >= 0 else ""
	fund_change_label.text = "总利润：%s%s（%+d%%）" % [sign, _format_currency(total_profit), profit_percent]
	# 利润颜色
	if total_profit >= 0:
		fund_change_label.add_theme_color_override("font_color", Color("5ee8e8"))
	else:
		fund_change_label.add_theme_color_override("font_color", Color("ff6b6b"))


## 显示审核生涯统计
func show_career_stats(years: int, total_approved: int, total_interest: int, total_bad_debt: int, extra_narrative: String = "") -> void:
	# 清空旧内容
	for child: Node in career_vbox.get_children():
		child.queue_free()

	_add_career_line("运营年数：%d 年" % years)
	_add_career_line("批准贷款：%d 笔" % total_approved)
	_add_career_line("总利息收入：%s" % _format_currency(total_interest))
	_add_career_line("总坏账损失：%s" % _format_currency(total_bad_debt))

	if extra_narrative != "":
		_add_career_line("")
		_add_career_line(extra_narrative)


## 设置按钮显示状态：正常继续 / 失败 / 通关
func set_button_mode(mode: String) -> void:
	match mode:
		"normal":
			## 正常：只有进入下一年
			next_year_btn.show()
			restart_btn.hide()
			back_to_menu_btn.hide()
		"game_over":
			## 失败：只有重新开始和返回主菜单
			next_year_btn.hide()
			restart_btn.show()
			back_to_menu_btn.show()
		"victory":
			## 通关：三个按钮都显示
			next_year_btn.show()
			restart_btn.show()
			back_to_menu_btn.show()


## 隐藏资金变动和审核生涯区域，并清空上一年的还款记录（揭晓动画开始前调用）
func hide_fund_and_career() -> void:
	for node: Control in _get_fund_career_nodes():
		node.hide()
	# 立即清空上一年的还款记录，避免界面弹出时短暂闪现旧内容
	_clear_children_immediate(repaid_vbox)
	_clear_children_immediate(ongoing_vbox)
	_clear_children_immediate(defaulted_vbox)


## 显示资金变动和审核生涯区域（揭晓动画结束后调用，带淡入效果）
func reveal_fund_and_career() -> void:
	for node: Control in _get_fund_career_nodes():
		node.modulate.a = 0.0
		node.show()
	var fade: Tween = create_tween()
	for node: Control in _get_fund_career_nodes():
		fade.parallel().tween_property(node, "modulate:a", 1.0, 0.3)
	await fade.finished


## 获取资金变动和审核生涯相关的所有节点
func _get_fund_career_nodes() -> Array[Control]:
	var nodes: Array[Control] = [
		fund_title, interest_income_label, bad_debt_label,
		colony_tax_label, fund_change_label, fund_sep,
		career_title, career_vbox, button_sep,
	]
	return nodes


## 显示结算界面（淡入 + 缩放弹出）
func show_report() -> void:
	_kill_tween()
	# 设置初始状态
	modulate.a = 0.0
	scale = Vector2(0.9, 0.9)
	pivot_offset = size * 0.5
	show()
	# 创建动画
	_tween = create_tween().set_parallel(true)
	_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "modulate:a", 1.0, _show_duration)
	_tween.tween_property(self, "scale", Vector2.ONE, _show_duration)
	await _tween.finished
	_tween = null


## 隐藏结算界面（淡出 + 缩放收缩）
func hide_report() -> void:
	if not visible:
		return
	_kill_tween()
	_is_revealing = false
	pivot_offset = size * 0.5
	_tween = create_tween().set_parallel(true)
	_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "modulate:a", 0.0, _hide_duration)
	_tween.tween_property(self, "scale", Vector2(0.95, 0.95), _hide_duration)
	await _tween.finished
	_tween = null
	hide()


## 终止当前活跃的 Tween
func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
		_tween = null


## --- 私有辅助方法 ---

## 清空容器中的所有子节点（延迟释放，用于一般场景）
func _clear_children(container: Control) -> void:
	for child: Node in container.get_children():
		child.queue_free()


## 立即清空容器中的所有子节点（同步释放，避免闪现旧内容）
func _clear_children_immediate(container: Control) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()


## 向指定容器添加一行文本，返回创建的 Label
func _add_detail_line(container: Control, text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	container.add_child(label)
	return label


## 向审核生涯区域添加一行文本
func _add_career_line(text: String) -> void:
	var label: Label = Label.new()
	label.text = text
	career_vbox.add_child(label)


## 对 Label 播放水平震动效果
func _shake_label(label: Label) -> void:
	var original_x: float = label.position.x
	var shake_tween: Tween = create_tween()
	var step_time: float = shake_duration / float(shake_count * 2)
	for i: int in range(shake_count):
		var direction: float = 1.0 if i % 2 == 0 else -1.0
		shake_tween.tween_property(label, "position:x", original_x + shake_amplitude * direction, step_time)
		shake_tween.tween_property(label, "position:x", original_x, step_time)


## 格式化货币显示
func _format_currency(amount: int) -> String:
	var negative: bool = amount < 0
	var abs_amount: int = absi(amount)
	var text: String = str(abs_amount)
	var result: String = ""
	var count: int = 0
	for i: int in range(text.length() - 1, -1, -1):
		result = text[i] + result
		count += 1
		if count % 3 == 0 and i > 0:
			result = "," + result
	if negative:
		return "-" + result
	return result
