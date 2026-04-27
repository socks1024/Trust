# 彩蛋角色设计文档

> 纯数据驱动的彩蛋角色调度方案，复用现有 `ApplicantData` 和审核工作台，改动最小化。

---

## 一、方案概述

### 核心思路

**不新增任何场景或 UI**，彩蛋角色就是特殊的 `ApplicantData`，放在一个角色池中，`GameManager` 从第 3 年起每年随机抽取彩蛋角色插入申请者列表。每个彩蛋角色只出场 **1 次**，玩家在审核时偶遇这些奇葩申请人，会心一笑。

与教程系统的关系：
- 教程系统：第 1 年，`TutorialManager` 提供固定申请人列表
- 第 2 年：纯随机路人（过渡年）
- 第 3 年起：`GameManager` 从彩蛋角色池中随机抽取 + 随机路人

### 改动清单

| 改动项 | 类型 | 说明 |
|--------|------|------|
| `ApplicantData` | 改 | 新增 `custom_residence_name` 和 `custom_residence_description` 字段，`get_residence_location_name()` 优先返回自定义名称 |
| `ReviewDesk` | 改 | 居住地ⓘ按钮优先使用 `custom_residence_description` |
| `StoryCharacterPool` | 新增 | 小资源脚本，包含所有彩蛋角色的数组和每年抽取数量配置 |
| `GameManager` | 改 | `_get_applicants()` 中从池中随机抽取彩蛋角色；`_check_victory()` 实现通关判定 |
| `.tres` 文件 | 新增 | 每个彩蛋角色各一个 `.tres` 文件 |
| `story_character_pool.tres` | 新增 | 一个彩蛋角色池配置文件 |

---

## 二、新增资源脚本

### 2.1 `StoryCharacterPool`（彩蛋角色池）

**文件路径**：`res://content/data/gameplay/story_character_pool.gd`

```gdscript
class_name StoryCharacterPool
extends Resource
## 彩蛋角色池
##
## 包含所有彩蛋角色的申请者数据，GameManager 从第 3 年起
## 每年随机抽取指定数量的角色插入申请者列表。
## 已出场的角色不会重复出场。

## 所有彩蛋角色（在编辑器中逐个添加 .tres 文件）
@export var characters: Array[ApplicantData] = []
## 从第几年开始出场（默认第3年）
@export var start_year: int = 3
## 每年随机抽取的彩蛋角色数量
@export var per_year: int = 1
```

---

## 三、`GameManager` 改动

### 3.1 新增导出变量

```gdscript
## 彩蛋角色池（在编辑器中配置）
@export var story_pool: StoryCharacterPool = null
```

### 3.2 新增内部变量

```gdscript
## 尚未出场的彩蛋角色（运行时从池中复制，每抽取一个就移除）
var _remaining_story_characters: Array[ApplicantData] = []
```

在 `_ready()` 或游戏开始时初始化：

```gdscript
if story_pool != null:
	_remaining_story_characters = story_pool.characters.duplicate()
```

### 3.3 修改 `_get_applicants()`

在现有的随机路人生成逻辑之前，从彩蛋角色池中随机抽取：

```gdscript
## 获取当前年度的申请者列表
func _get_applicants() -> Array[ApplicantData]:
	# 教程年使用固定教学申请人（不打乱顺序）
	if _tutorial.is_tutorial_year():
		return _tutorial.get_tutorial_applicants()

	var result: Array[ApplicantData] = []

	# 从第 start_year 年起，每年随机抽取彩蛋角色
	if story_pool != null and _current_year >= story_pool.start_year:
		var pick_count: int = mini(story_pool.per_year, _remaining_story_characters.size())
		for i: int in range(pick_count):
			var idx: int = randi() % _remaining_story_characters.size()
			result.append(_remaining_story_characters[idx])
			_remaining_story_characters.remove_at(idx)

	# 生成随机路人
	if random_config != null:
		var count: int = randi_range(random_count_min, random_count_max)
		for i: int in range(count):
			result.append(random_config.generate_applicant())
	else:
		# 没有随机配置时使用手动配置的申请者池
		result.assign(applicant_pool)

	result.shuffle()
	return result
```

### 3.4 实现 `_check_victory()`

```gdscript
## 检查是否通关（所有彩蛋角色已出场完毕）
func _check_victory() -> bool:
	if story_pool == null or story_pool.characters.is_empty():
		return false
	return _remaining_story_characters.is_empty()
```

---

## 四、16 个彩蛋角色设计

> 每个角色只出场 1 次。设计原则：从现实人物或文娱作品中取材，放在"贷款审核"场景下制造强烈反差。

### 角色总览

| # | 角色名 | 职业 | 梗/来源 |
|---|--------|------|--------|
| 1 | 埃尔温·薛定谔 | 量子物理学家 | 薛定谔的猫 |
| 2 | 诸葛亮 | 军事顾问 | 三国演义 |
| 3 | 堂吉诃德·德·拉曼查 | 骑士 | 堂吉诃德 |
| 4 | 夜神月 | 大学生 | 死亡笔记 |
| 5 | 哆啦A梦 | 育儿机器人 | 哆啦A梦 |
| 6 | 瑞克·桑切斯 | 科学家 | 瑞克和莫蒂 |
| 7 | 凉宫春日 | 高中生 | 凉宫春日系列 |
| 8 | 罗辑 | 社会学教授 | 三体 |
| 9 | 埃隆·马斯克 | 企业家 | 现实人物 |
| 10 | 唐纳德·川普 | 政客/商人 | 现实人物 |
| 11 | 保罗·阿特雷德斯 | 贵族继承人 | 沙丘 |
| 12 | 韩·索罗 | 走私船长 | 星球大战 |
| 13 | 约翰-117 | 超级战士 | 光环 |
| 14 | 夏亚·阿兹纳布尔 | 新吉翁总帅 | 机动战士高达 |
| 15 | 成龙 | 演员/武术家 | 现实人物 |
| 16 | 阿尔伯特·爱因斯坦 | 物理学家 | 现实人物 |

---

### 角色详细设计

#### 1. 埃尔温·薛定谔 —— 量子物理学家

| 字段 | 值 |
|------|-----|
| `applicant_name` | 埃尔温·薛定谔 |
| `gender` | 男 |
| `age` | 55 |
| `profession` | 量子物理学家 |
| `profession_description` | 理论物理学界资深研究员，主要研究方向为量子力学及波动力学。曾提出著名的宏观量子叠加态思想实验。主要收入来源为大学教职薪酬及学术奖项奖金。 |
| `annual_income` | 80000 |
| `custom_residence_name` | 维也纳 |
| `custom_residence_description` | 位于奥地利维也纳大学物理系附近的教职工公寓。据走访调查，该住所内长期饲养有一只猫科动物，且室内常有不明实验设备运转声。 |
| `residence_type` | OWNED |
| `assets` | [{"category": "设备", "name": "量子计算机", "value": 120000}] |
| `debts` | [] |
| `loan_amount` | 30000 |
| `loan_purpose` | 购买实验用猫粮 |
| `loan_period` | 2 |
| `interest_rate_tier` | LOW |
| `statement` | 听着，我急需这笔钱来维持我的实验。在你盖下那个该死的印章之前，这笔贷款处于"批准"和"拒绝"的叠加态。\n\n你问猫怎么样了？它现在……既活着又死了，这取决于你是否批准我的贷款。但猫粮账单是确定的，每个月都在增长。\n\n所以，赶紧批了吧，别让波函数坍缩到错误的方向。 |
| `bargain_sensitivity` | Normal |

---

#### 2. 诸葛亮 —— 军事顾问

| 字段 | 值 |
|------|-----|
| `applicant_name` | 诸葛亮 |
| `gender` | 男 |
| `age` | 46 |
| `profession` | 军事顾问 |
| `profession_description` | 蜀汉政权核心管理层，担任丞相及首席军事战略顾问。具备极强的微观管理倾向，主导多项大型军事工程及后勤装备研发（如木牛流马）。薪资水平一般，但实际掌控国家财政大权。 |
| `annual_income` | 60000 |
| `custom_residence_name` | 汉中 |
| `custom_residence_description` | 蜀汉政权北部边境军事重镇的临时指挥所。该处安保严密，常年驻扎大量军队，且周边有大规模军屯农业设施。 |
| `residence_type` | RENTED |
| `assets` | [{"category": "设备", "name": "星际沙盘推演系统", "value": 50000}] |
| `debts` | [{"category": "商业", "name": "北伐军费垫付", "amount": 80000, "status": 0}] |
| `loan_amount` | 50000 |
| `loan_purpose` | 雇佣十万大学生北伐 |
| `loan_period` | 3 |
| `interest_rate_tier` | MEDIUM |
| `statement` | 亮受先帝之托，已六出祁山，然皆因兵力匮乏而功败垂成。\n\n今亮顿悟，欲招募十万应届大学生！此辈虽无实战经验，然精力充沛、薪资低廉，且精通PPT制作，实乃冲锋陷阵、汇报战果之良才。\n\n先以实习之名用之，若能克复中原，再议转正。望阁下速批此款，亮感激涕零！ |
| `repay_probability` | 0.35 |
| `bargain_sensitivity` | Confident |

---

#### 3. 堂吉诃德·德·拉曼查 —— 骑士

| 字段 | 值 |
|------|-----|
| `applicant_name` | 堂吉诃德·德·拉曼查 |
| `gender` | 男 |
| `age` | 50 |
| `profession` | 骑士 |
| `profession_description` | 地方乡绅阶层，自封为游侠骑士。长期沉迷于中世纪骑士文学，存在严重的认知偏差与妄想症状。目前无稳定收入来源，主要依靠变卖祖传不动产维持其所谓的"冒险"活动。 |
| `annual_income` | 8000 |
| `custom_residence_name` | 拉曼查 |
| `custom_residence_description` | 位于西班牙拉曼查地区的一处破败乡村庄园。建筑年久失修，内部堆满各类过时的骑士小说及生锈的冷兵器。 |
| `residence_type` | OWNED |
| `assets` | [{"category": "交通工具", "name": "瘦马一匹", "value": 500}, {"category": "设备", "name": "生锈盔甲", "value": 200}] |
| `debts` | [{"category": "商业", "name": "风车维修赔偿", "amount": 12000, "status": 1}] |
| `loan_amount` | 20000 |
| `loan_purpose` | 讨伐巨人 |
| `loan_period` | 2 |
| `interest_rate_tier` | MEDIUM |
| `statement` | 尊贵的金库守护者啊！吾乃拉曼查的堂吉诃德，正义的化身！\n\n吾急需这笔资金去讨伐那些伪装成风力发电站的邪恶巨人！上次交锋时，吾被那巨人挥舞的巨大手臂击飞，吾那愚钝的侍从桑丘竟说那是风车！荒谬！\n\n待吾斩下巨人首级，定将战利品献于阁下！ |
| `repay_probability` | 0.05 |
| `bargain_sensitivity` | AlwaysAccept |

---

#### 4. 夜神月 —— 大学生

| 字段 | 值 |
|------|-----|
| `applicant_name` | 夜神月 |
| `gender` | 男 |
| `age` | 23 |
| `profession` | 大学生 |
| `profession_description` | 东应大学在读本科生，学业成绩优异，常年位居全国模拟考试榜首。目前无合法申报的收入来源，但声称正在筹备一项"改变全球秩序"的宏大项目。 |
| `annual_income` | 0 |
| `custom_residence_name` | 东京 |
| `custom_residence_description` | 位于日本关东地区的一处标准中产阶级独栋住宅。申请人卧室门锁有被改造过的痕迹，且抽屉内疑似装有复杂的防盗机关。 |
| `residence_type` | BORROWED |
| `assets` | [{"category": "设备", "name": "黑色笔记本", "value": 5000}] |
| `debts` | [] |
| `loan_amount` | 100000 |
| `loan_purpose` | 创建新世界 |
| `loan_period` | 1 |
| `interest_rate_tier` | LOW |
| `statement` | 这笔钱将用于构建一个没有犯罪的完美新世界。具体细节？抱歉，这属于最高机密。\n\n你只需要明白一点：在我的新世界里，按时还贷的良民会得到庇护，而那些恶意逾期的老赖……他们的心脏可能会不太好。\n\n呵呵，开个玩笑。作为全国模考第一，我的信用评级应该是完美的吧？ |
| `repay_probability` | 0.20 |
| `bargain_sensitivity` | Confident |

---

#### 5. 哆啦A梦 —— 育儿机器人

| 字段 | 值 |
|------|-----|
| `applicant_name` | 哆啦A梦 |
| `gender` | 男 |
| `age` | -86 |
| `profession` | 育儿机器人 |
| `profession_description` | 22世纪量产型猫型育儿机器人（次品）。主要职责为监护并纠正特定未成年人的不良行为模式。其携带的四次元空间袋内含大量高价值未来科技产品，但均属租赁性质，无实际所有权。当前无合法收入来源。 |
| `annual_income` | 0 |
| `custom_residence_name` | 东京 |
| `custom_residence_description` | 东京都练马区野比宅邸二楼卧室壁橱。空间狭小但符合该型号机器人的休眠需求。 |
| `residence_type` | BORROWED |
| `assets` | [{"category": "设备", "name": "四次元口袋", "value": 999999}] |
| `debts` | [{"category": "消费贷", "name": "铜锣烧赊账", "amount": 8000, "status": 0}] |
| `loan_amount` | 15000 |
| `loan_purpose` | 购买铜锣烧 |
| `loan_period` | 1 |
| `interest_rate_tier` | LOW |
| `statement` | 拜托了！大雄那个笨蛋今天又考了零分，还被胖虎揍了一顿，我如果不吃点铜锣烧补充能量，真的会短路的！\n\n我的道具都是租来的不能抵押，但我可以借你任意门用一天！去夏威夷度假怎么样？或者用时光机去看看明天的彩票号码？\n\n求求你了，就借我这点钱吧！ |
| `repay_probability` | 0.80 |
| `bargain_sensitivity` | NeedMoney |

---

#### 6. 瑞克·桑切斯 —— 科学家

| 字段 | 值 |
|------|-----|
| `applicant_name` | 瑞克·桑切斯 |
| `gender` | 男 |
| `age` | 70 |
| `profession` | 科学家 |
| `profession_description` | 跨维度独立研究员。掌握多项足以引发宇宙级灾难的未授权技术。长期寄居于直系亲属家中，无合法纳税记录。其发明的潜在商业价值极高，但因其极度不稳定的精神状态和反社会倾向，投资风险被评估为最高级。 |
| `annual_income` | 0 |
| `custom_residence_name` | 西雅图 |
| `custom_residence_description` | 史密斯宅邸附属车库。已被非法改造为高危跨维度实验室，存放有大量未登记的放射性物质和外星生物样本。 |
| `residence_type` | BORROWED |
| `assets` | [{"category": "交通工具", "name": "飞船", "value": 500000}, {"category": "设备", "name": "传送枪", "value": 200000}] |
| `debts` | [{"category": "商业", "name": "跨维度赌债", "amount": 50000, "status": 1}] |
| `loan_amount` | 30000 |
| `loan_purpose` | 跨维度实验 |
| `loan_period` | 1 |
| `interest_rate_tier` | HIGH |
| `statement` | *嗝*……听着，官僚主义的走狗，我需要这笔钱买点浓缩暗物质。别跟我提什么信用评估，我在C-137维度的信用分比你们整个星球的GDP都高。\n\n你要是不批，我就用传送枪去另一个维度的你那里贷，顺便把这个维度的你变成一只*嗝*……一只只会吃自己排泄物的弗洛格兽。\n\n快点签字，我赶时间。 |
| `repay_probability` | 0.15 |
| `bargain_sensitivity` | AlwaysReject |

---

#### 7. 凉宫春日 —— 高中生

| 字段 | 值 |
|------|-----|
| `applicant_name` | 凉宫春日 |
| `gender` | 女 |
| `age` | 16 |
| `profession` | 高中生 |
| `profession_description` | 县立北高在读学生，非官方社团SOS团创立者及实际控制人。经多方秘密机构评估，该个体具备无意识改变现实的极度危险能力。当前无独立经济能力，其行为模式具有极高的不可预测性。 |
| `annual_income` | 0 |
| `custom_residence_name` | 西宫市 |
| `custom_residence_description` | 县立北高文艺部活动室。已被该个体强行征用为社团活动据点，内部设施简陋，仅有一台来源不明的旧电脑。 |
| `residence_type` | BORROWED |
| `assets` | [] |
| `debts` | [] |
| `loan_amount` | 50000 |
| `loan_purpose` | SOS团活动经费 |
| `loan_period` | 1 |
| `interest_rate_tier` | MEDIUM |
| `statement` | 我对普通的贷款没有兴趣！如果你们银行里有外星人、未来人、异世界人或者超能力者，就让他们来给我办手续！\n\n我们SOS团要拍一部震惊世界的电影，需要五万块经费。不批的话，后果你自己想吧，我可不保证这个世界还能维持现状。 |
| `repay_probability` | 0.20 |
| `bargain_sensitivity` | Confident |

---

#### 8. 罗辑 —— 社会学教授

| 字段 | 值 |
|------|-----|
| `applicant_name` | 罗辑 |
| `gender` | 男 |
| `age` | 38 |
| `profession` | 社会学教授 |
| `profession_description` | 前大学社会学教授，现任联合国行星防御理事会指定面壁者。享有极高的资源调配权限，但其真实战略意图被严格保密。收入来源为联合国专项津贴，资金流向常呈现出难以理解的非理性特征。 |
| `annual_income` | 70000 |
| `custom_residence_name` | 纽约 |
| `custom_residence_description` | 联合国行星防御理事会提供的最高安保级别住所。该个体近期频繁表达对该居住环境的不满，并要求迁移至自然水域附近。 |
| `residence_type` | RENTED |
| `assets` | [{"category": "存款", "name": "面壁者专项资金", "value": 100000}] |
| `debts` | [] |
| `loan_amount` | 80000 |
| `loan_purpose` | 购买湖畔别墅 |
| `loan_period` | 3 |
| `interest_rate_tier` | MEDIUM |
| `statement` | 我需要一栋湖畔别墅，还要一瓶罗曼尼·康帝，以及一幅蒙娜丽莎的赝品。为什么？这是计划的一部分。你不需要理解，你只需要批准。\n\n如果我不去那个湖边，人类文明可能就完蛋了。当然，如果你觉得人类的存亡不值这八万块钱，你大可以拒绝。\n\n反正……这也是计划的一部分。 |
| `repay_probability` | 1.0 |
| `bargain_sensitivity` | Normal |

---

#### 9. 埃隆·马斯克 —— 企业家

| 字段 | 值 |
|------|-----|
| `applicant_name` | 埃隆·马斯克 |
| `gender` | 男 |
| `age` | 52 |
| `profession` | 企业家 |
| `profession_description` | 跨国科技企业创始人及首席执行官。业务版图涵盖航天发射、新能源汽车制造及神经科技研发。个人资产评估极高，但资金多沉淀于企业股权，现金流状况呈现周期性紧张。 |
| `annual_income` | 999999 |
| `custom_residence_name` | 博卡奇卡 |
| `custom_residence_description` | 位于德克萨斯州博卡奇卡的航天发射基地。申请人常驻于基地内的临时装配式住宅，以便全天候监控航天器测试进度。 |
| `residence_type` | OWNED |
| `assets` | [{"category": "交通工具", "name": "可回收火箭×3", "value": 800000}, {"category": "设备", "name": "脑机接口原型", "value": 200000}] |
| `debts` | [{"category": "商业", "name": "火星殖民计划预算超支", "amount": 500000, "status": 0}] |
| `loan_amount` | 500000 |
| `loan_purpose` | 火星殖民第二期 |
| `loan_period` | 3 |
| `interest_rate_tier` | HIGH |
| `statement` | 听着，火星城市的第一期工程马上就要动工了。上一期预算超标？那是因为火箭炸了三次，但那是收集数据的必要过程！第四次绝对能成。\n\n你问我为什么不卖股票？开什么玩笑，我一抛售股价就得崩盘，到时候媒体又要乱写。\n\n批了这笔钱，我保证给你留一张去火星的VIP单程票，怎么样？ |
| `repay_probability` | 0.50 |
| `bargain_sensitivity` | Confident |

---

#### 10. 唐纳德·川普 —— 政客/商人

| 字段 | 值 |
|------|-----|
| `applicant_name` | 唐纳德·川普 |
| `gender` | 男 |
| `age` | 78 |
| `profession` | 政客 |
| `profession_description` | 前国家元首及大型房地产集团实际控制人。名下持有大量商业地产及高尔夫球场。曾有多次企业破产重组记录，目前面临多项未决诉讼，财务状况受法律程序影响较大。 |
| `annual_income` | 400000 |
| `custom_residence_name` | 海湖庄园 |
| `custom_residence_description` | 位于佛罗里达州棕榈滩的顶级私人俱乐部及庄园。作为申请人的主要居所及社交中心，安保级别极高。 |
| `residence_type` | OWNED |
| `assets` | [{"category": "住房", "name": "川普大厦", "value": 900000}, {"category": "存款", "name": "竞选基金", "value": 200000}] |
| `debts` | [{"category": "商业", "name": "多项法律诉讼费", "amount": 300000, "status": 0}] |
| `loan_amount` | 400000 |
| `loan_purpose` | 建墙 |
| `loan_period` | 2 |
| `interest_rate_tier` | HIGH |
| `statement` | 我要建一堵墙，一堵非常、非常巨大的墙！把那些坏账和糟糕的借款人都挡在外面。没有人比我更懂贷款，believe me，我是你们见过的最棒的客户。\n\n违约？那叫战略性破产，是非常聪明的商业手段！Make your bank great again！\n\n如果你不批这笔贷款，那你一定是被Fake News洗脑了，Sad！ |
| `repay_probability` | 0.35 |
| `bargain_sensitivity` | Confident |

---

#### 11. 保罗·阿特雷德斯 —— 贵族继承人

| 字段 | 值 |
|------|-----|
| `applicant_name` | 保罗·阿特雷德斯 |
| `gender` | 男 |
| `age` | 20 |
| `profession` | 贵族继承人 |
| `profession_description` | 厄拉科斯星区实际控制人及阿特雷德斯家族继承人。垄断了全宇宙唯一的高价值战略物资（香料）的开采与贸易。具备极高的偿还能力，但面临复杂的政治风险。 |
| `annual_income` | 200000 |
| `custom_residence_name` | 厄拉科斯 |
| `custom_residence_description` | 极端干旱的沙漠行星，系战略物资香料的唯一产地。申请人目前居住于沙漠深处的地下掩体中。 |
| `residence_type` | OWNED |
| `assets` | [{"category": "设备", "name": "香料储备", "value": 600000}, {"category": "设备", "name": "蒸馏服", "value": 10000}] |
| `debts` | [] |
| `loan_amount` | 150000 |
| `loan_purpose` | 香料期货投资 |
| `loan_period` | 2 |
| `interest_rate_tier` | MEDIUM |
| `statement` | 我已经看到了未来。在无数条交织的时间线里，你最终都签下了这份贷款协议。\n\n香料就是权力，控制了香料就控制了整个宇宙的命脉。我要用这笔资金进行香料期货的杠杆操作。风险？对我来说不存在风险，因为结果早已注定。\n\n有些未来太过残酷，我不想向你描述，所以……签字吧。 |
| `repay_probability` | 0.65 |
| `bargain_sensitivity` | Confident |

---

#### 12. 韩·索罗 —— 走私船长

| 字段 | 值 |
|------|-----|
| `applicant_name` | 韩·索罗 |
| `gender` | 男 |
| `age` | 35 |
| `profession` | 走私船长 |
| `profession_description` | 银河系地下经济活跃参与者，主营高风险违禁品运输。收入极不稳定，且常面临帝国军方及黑帮势力的双重追捕。 |
| `annual_income` | 60000 |
| `custom_residence_name` | 千年隼号 |
| `custom_residence_description` | 经高度非法改装的YT-1300轻型货船，具备超光速引擎。该船只同时作为申请人的主要居所与作案工具。 |
| `residence_type` | RENTED |
| `assets` | [{"category": "交通工具", "name": "千年隼号", "value": 400000}] |
| `debts` | [{"category": "赌博", "name": "欠赫特人的钱", "amount": 80000, "status": 1}] |
| `loan_amount` | 80000 |
| `loan_purpose` | 还债和飞船维修 |
| `loan_period` | 1 |
| `interest_rate_tier` | HIGH |
| `statement` | 听着，伙计，我急需这笔钱。贾巴那个大鼻涕虫派了赏金猎人到处找我，上一个在坎蒂纳酒吧差点打中我，当然，是我先开的枪。\n\n我的千年隼号是银河系最快的飞船，12秒差距跑完科舍尔航线！什么距离单位？别管那些书呆子的理论了！\n\n只要修好超空间引擎，我跑一趟大单子就能连本带利还给你。你要是不信，问我的副驾驶，他是个两米高的伍基人，脾气可不太好。 |
| `repay_probability` | 0.45 |
| `bargain_sensitivity` | NeedMoney |

---

#### 13. 约翰-117 —— 超级战士

| 字段 | 值 |
|------|-----|
| `applicant_name` | 约翰-117 |
| `gender` | 男 |
| `age` | 41 |
| `profession` | 超级战士 |
| `profession_description` | 联合国太空司令部（UNSC）斯巴达-II计划特种兵，编号117。长期服役于前线，具备极高的战术素养与生存能力。军饷由军方按时发放。 |
| `annual_income` | 120000 |
| `custom_residence_name` | UNSC无尽号 |
| `custom_residence_description` | UNSC无尽号超级航母。申请人无固定地面居所，长期处于战斗部署或冷冻休眠状态。 |
| `residence_type` | DORMITORY |
| `assets` | [{"category": "设备", "name": "雷神之锤动力装甲", "value": 500000}] |
| `debts` | [] |
| `loan_amount` | 60000 |
| `loan_purpose` | 装甲升级 |
| `loan_period` | 1 |
| `interest_rate_tier` | MEDIUM |
| `statement` | 长官，我需要申请资金升级雷神之锤装甲的护盾模块。星盟的残党还在活动，洪魔的威胁也从未真正消除。\n\nUNSC后勤部削减了预算，说现在是和平时期。但我的AI告诉我，新的威胁正在逼近。\n\n我不需要休息，我只需要武器和装备。这笔钱关系到下一次任务的成败，而我的任务，是保护人类。请批准。 |
| `repay_probability` | 0.80 |
| `bargain_sensitivity` | Normal |

---

#### 14. 夏亚·阿兹纳布尔 —— 新吉翁总帅

| 字段 | 值 |
|------|-----|
| `applicant_name` | 夏亚·阿兹纳布尔 |
| `gender` | 男 |
| `age` | 34 |
| `profession` | 新吉翁总帅 |
| `profession_description` | 新吉翁军总帅，传奇机动战士驾驶员，人称“赤色彗星”。具备极高的政治影响力和军事指挥能力。收入来源为新吉翁军费及个人资产。 |
| `annual_income` | 150000 |
| `custom_residence_name` | 斯威特·沃特 |
| `custom_residence_description` | 位于L5宙域的难民收容殖民卫星，现为新吉翁军的秘密据点。 |
| `residence_type` | DORMITORY |
| `assets` | [{"category": "设备", "name": "沙扎比", "value": 900000}] |
| `debts` | [{"category": "商业", "name": "阿克西斯购买尾款", "amount": 500000, "status": 0}] |
| `loan_amount` | 200000 |
| `loan_purpose` | 购买小行星阿克西斯 |
| `loan_period` | 3 |
| `interest_rate_tier` | MEDIUM |
| `statement` | 地球上的人类灵魂被重力束缚得太久了。为了纠正这个错误，我需要买下阿克西斯，把它降落到地球上，引发核子冬天。\n\n这笔贷款将用于支付阿克西斯的尾款。你问我怎么还钱？等地球被净化，全人类都移居宇宙，新吉翁将统治一切，区区贷款算什么。\n\n阿姆罗那个家伙肯定会来阻止我，所以我还需要升级沙扎比的武装。签字吧，为了全人类的革新。 |
| `repay_probability` | 0.40 |
| `bargain_sensitivity` | Confident |

---

#### 15. 成龙 —— 演员/武术家

| 字段 | 值 |
|------|-----|
| `applicant_name` | 成龙 |
| `gender` | 男 |
| `age` | 70 |
| `profession` | 演员 |
| `profession_description` | 国际知名动作电影演员及导演。以拒绝使用替身、亲自完成高危特技动作著称。收入来源广泛，具备极高的商业价值与偿还能力。 |
| `annual_income` | 300000 |
| `custom_residence_name` | 香港 |
| `custom_residence_description` | 位于香港半山区的私人高档住宅。安保严密，内部藏有大量电影道具及个人收藏品。 |
| `residence_type` | OWNED |
| `assets` | [{"category": "住房", "name": "豪宅", "value": 500000}, {"category": "存款", "name": "片酬积蓄", "value": 400000}] |
| `debts` | [] |
| `loan_amount` | 200000 |
| `loan_purpose` | 拍新电影 |
| `loan_period` | 1 |
| `interest_rate_tier` | LOW |
| `statement` | 大哥，是这样的，我准备筹拍一部新戏。这次的动作设计绝对是前所未有的！我要从直升机上跳到一辆正在爆炸的火车上，然后再滑板冲下雪山！\n\n保险公司？哎呀，那些保险公司早就把我拉黑名单了，他们说我拍电影太危险了。\n\n你放心，我的电影全球发行，票房绝对有保证，这笔钱很快就能还上。Duang的一下就还上了！ |
| `repay_probability` | 0.90 |
| `bargain_sensitivity` | Confident |

---

#### 16. 阿尔伯特·爱因斯坦 —— 物理学家

| 字段 | 值 |
|------|-----|
| `applicant_name` | 阿尔伯特·爱因斯坦 |
| `gender` | 男 |
| `age` | 55 |
| `profession` | 物理学家 |
| `profession_description` | 普林斯顿高等研究院理论物理学教授，诺贝尔物理学奖获得者。学术地位极高，但个人财务管理能力较弱，收入主要依赖教职薪水。 |
| `annual_income` | 60000 |
| `custom_residence_name` | 普林斯顿 |
| `custom_residence_description` | 位于新泽西州普林斯顿默瑟街112号的普通住宅。内部堆满手稿与书籍，生活设施简朴。 |
| `residence_type` | RENTED |
| `assets` | [{"category": "存款", "name": "诺贝尔奖金", "value": 80000}] |
| `debts` | [{"category": "消费贷", "name": "前妻赡养费", "amount": 40000, "status": 0}] |
| `loan_amount` | 50000 |
| `loan_purpose` | 统一场论研究 |
| `loan_period` | 3 |
| `interest_rate_tier` | MEDIUM |
| `statement` | 年轻人，时间是相对的，但银行的还款期限显然是绝对的。我现在的研究到了关键阶段，我试图将引力和电磁力统一起来，这是一个比相对论更宏大的构想。\n\n可惜，研究院的薪水不足以支撑我升级一些必要的计算设备。上帝不掷骰子，我也不喜欢在财务上冒险，但我确实需要这笔资金。\n\n如果我的理论成功了，它将改变人类对宇宙的认知。这难道不比投资那些工厂更有价值吗？ |
| `repay_probability` | 0.55 |
| `bargain_sensitivity` | Normal |

---

## 五、通关与游戏流程

### 流程图

```
第1年（教程年）
  │  TutorialManager 提供固定申请人
  ▼
第2年（过渡年）
  │  纯随机路人
  ▼
第3年起（正式游戏）
  │  GameManager._get_applicants():
  │    1. 从彩蛋角色池中随机抽取（每年 per_year 个，不重复）
  │    2. 随机生成路人
  │    3. shuffle 混合
  ▼
年度结算
  │  _check_victory():
  │    彩蛋角色池清空 → 通关
  │  资金池 < 0 → 游戏失败
  ▼
通关后 → 无尽模式（继续随机路人，不再有彩蛋角色）
```

---

## 六、配置工作流（策划操作步骤）

### 第一步：创建脚本文件

1. 创建 `res://content/data/gameplay/story_character_pool.gd`（StoryCharacterPool 资源脚本）

### 第二步：创建彩蛋角色的 `.tres` 文件

1. 在 `res://content/data/gameplay/applicants/` 目录下
2. 右键 → 新建资源 → 选择 `ApplicantData`
3. 按命名规则保存（如 `easter_schrodinger.tres`）
4. 在检查器中填写所有字段

### 第三步：创建角色池

1. 右键 → 新建资源 → 选择 `StoryCharacterPool`
2. 保存为 `res://content/data/gameplay/story_character_pool.tres`
3. 在检查器中设置 `start_year`（默认 3）和 `per_year`（默认 1）
4. 展开 `characters`，逐个拖入彩蛋角色的 `.tres` 文件

### 第四步：挂载到 GameManager

1. 在场景树中选中 `GameManager` 节点
2. 在检查器中找到 `Story Pool` 属性
3. 拖入 `story_character_pool.tres`
