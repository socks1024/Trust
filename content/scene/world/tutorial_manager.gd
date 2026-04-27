extends Node
## 教程管理器
##
## 管理第1年的教程流程：开局弹窗、每位申请人前的提示弹窗、结算弹窗。
## 挂载为 GameManager 的兄弟节点，通过信号与 GameManager 协作。

## 教程弹窗关闭时发出，通知 GameManager 可以继续
signal tutorial_step_completed

## 教程弹窗引用
@onready var popup: Panel = %TutorialPopup
## 教学用申请人列表（按顺序配置）
@export var tutorial_applicants: Array[ApplicantData] = []

## 是否处于教程年（第1年）
var _is_tutorial_year: bool = true


## --- 开局弹窗 ---

## 显示开局介绍弹窗
func show_intro_popup() -> void:
	if popup == null:
		tutorial_step_completed.emit()
		return
	var pages: Array[String] = [
		tr("TUT_INTRO_1"),
		tr("TUT_INTRO_2"),
		tr("TUT_INTRO_3"),
		tr("TUT_INTRO_4"),
	]
	popup.show_pages(pages, tr("TUT_TITLE_INTRO"), tr("TUT_BTN_START"))
	await popup.popup_closed
	tutorial_step_completed.emit()


## --- 申请人前弹窗 ---

## 显示指定申请人索引对应的教学提示弹窗
func show_applicant_hint(applicant_index: int) -> void:
	if popup == null:
		tutorial_step_completed.emit()
		return

	var pages: Array[String] = _get_applicant_hint_pages(applicant_index)
	if pages.is_empty():
		tutorial_step_completed.emit()
		return

	var titles: Array[String] = [tr("TUT_TITLE_HINT_0"), tr("TUT_TITLE_HINT_1"), tr("TUT_TITLE_HINT_2")]
	var title: String = titles[applicant_index] if applicant_index < titles.size() else "提示"
	popup.show_pages(pages, title, tr("TUT_BTN_REVIEW"))
	await popup.popup_closed
	tutorial_step_completed.emit()


## 获取指定申请人索引的提示页面
func _get_applicant_hint_pages(index: int) -> Array[String]:
	match index:
		0:
			# 申请人#1：介绍面板布局
			var result: Array[String] = [
				tr("TUT_HINT_0_1"),
			]
			return result
		1:
			# 申请人#2：介绍负债与逾期
			var result: Array[String] = [
				tr("TUT_HINT_1_1"),
			]
			return result
		2:
			# 申请人#3：介绍审批条件（利率、抵押、接受度）
			var result: Array[String] = [
				tr("TUT_HINT_2_1"),
				tr("TUT_HINT_2_2"),
				tr("TUT_HINT_2_3"),
				tr("TUT_HINT_2_4"),
			]
			return result
		_:
			var result: Array[String] = []
			return result


## --- 结算弹窗 ---

## 显示结算界面介绍弹窗
func show_report_popup() -> void:
	if popup == null:
		tutorial_step_completed.emit()
		return
	var pages: Array[String] = [
		tr("TUT_REPORT_1"),
		tr("TUT_REPORT_2"),
		tr("TUT_REPORT_3"),
		tr("TUT_REPORT_4"),
	]
	popup.show_pages(pages, tr("TUT_TITLE_REPORT"), tr("TUT_BTN_REPORT"))
	await popup.popup_closed
	tutorial_step_completed.emit()


## --- 状态查询 ---

## 当前是否为教程年
func is_tutorial_year() -> bool:
	return _is_tutorial_year


## 获取教学用申请人列表
func get_tutorial_applicants() -> Array[ApplicantData]:
	return tutorial_applicants


## 结束教程年（进入第2年后调用）
func end_tutorial() -> void:
	_is_tutorial_year = false
