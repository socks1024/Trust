class_name StorySchedule
extends Resource
## 彩蛋角色池
##
## 包含所有彩蛋角色的申请者数据。
## GameManager 每年从池中随机抽取角色插入当年申请者列表，已出场的不再重复。

## 彩蛋角色池（在编辑器中添加）
@export var characters: Array[ApplicantData] = []
