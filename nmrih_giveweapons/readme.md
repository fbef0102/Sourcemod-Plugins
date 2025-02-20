
# Description | 內容
Give weapons and items in no more rooms in hell

* Apply to | 適用於
	```
	No More Room in Hell
	```
	
* <details><summary>How does it work?</summary>

	* Admins type ```!admin``` -> Give/Spawn item
		* Give: Directly give weapon in player's inventory, hold weapon if inventory is full
		* Spawn: Spawn weapon in player's location
</details>

* Require | 必要安裝
<br/>None

* <details><summary>ConVar | 指令</summary>

	* cfg/sourcemod/nmrih_giveweapons.cfg
		```php
		// Hide admin activity.
		nmrih_giveweapons_silent "1"
		```
</details>

* Translation Support | 支援翻譯
	```
	translations/nmrih_giveweapons.phrases.txt
	```

* <details><summary>Changelog | 版本日誌</summary>

	* v1.1 (2025-2-20)
		* Add Inventory Box (Duffle Bag)
		* Optimize Code and menu

	* v1.0 (2024-12-17)
		* Add Inventory Box and Gene Therapy
	
	* [Original By Leonardo](https://forums.alliedmods.net/showthread.php?t=232911)
</details>

- - - -
# 中文說明
給予武器與物資

* 適用於
	```
	地獄已滿
	```

* 原理
	* 管理員輸入```!admin```-> 給予/生成 物資
		* 給予: 直接給玩家武器, 如果玩家背包已滿則改成拿著
		* 生成: 生成武器在玩家所在的位置

* <details><summary>指令中文介紹 (點我展開)</summary>

	* cfg/sourcemod/nmrih_giveweapons.cfg
		```php
		// 為1時，不顯示訊息
		nmrih_giveweapons_silent "1"
		```
</details>



