https://forums.alliedmods.net/showthread.php?t=329223
# Description | 內容
Analyse and logs entity classes delta when the total number of entities on the map exceeds a pre-prefined maximum

* Apply to | 適用於
	```
	Any Source Game
	```

* Require | 必要安裝
    1. [left4dhooks](https://forums.alliedmods.net/showthread.php?t=321696)

* <details><summary>How does it work?</summary>

	* When the total number of networked entities become > 2048* (depends on your game), server receive crash
		* Newer games have higher limits.
		* Crash Reason: ```ED_Alloc: no free edicts```
	* This plugin can help you with manual searching for a reason of entities leaking
		* Admin types ```!entlog```, create file ```logs/entity_limit_xxx.log``` and log all entities information
		* Logging all entities in file ```logs/entity_limit_xxx.log``` whenever the total number of networked entities almost reach the limit
</Chargedetails>

* <details><summary>ConVar | 指令</summary>

	* cfg/sourcemod/entity_limit_logger.cfg
		```php
		// Delay to be used after map start to create entities snapshot for calculating the entities delta when a leak happens
		entity_limit_logger_delay "10.0"

		// Plugin creates report when the number of free entities is less than this ConVar
		entity_limit_logger_unsafe_left "100"
		```
</details>

* <details><summary>Command | 命令</summary>

	* **Creates entities report (Access: ADMFLAG_ROOT)**
		```php
		sm_entlog
		sm_logent
		```

	* **Creates entities snapshot which is to be used for calculating the entities delta (when leak happens or sm_entlog used) (Access: ADMFLAG_ROOT)**
		```php
		sm_entsnap
		```
</details>

* <details><summary>Changelog | 版本日誌</summary>

	* v1.0h (2025-10-11)
		* Add NON-NETWORKING ENTITIES and NETWORKING ENTITIES
		* Print more entity information to log file
		* Update cmds, log
		* Use left4dhooks to detect if entity is in saferoom in l4d1/2
		* Optimize code and improve performance

	* v2.0
        * [Original Plugin by Dragokas](https://forums.alliedmods.net/showthread.php?t=329223)
</details>

- - - -
# 中文說明
產生文件記錄地圖當前所有實體的資訊與總數量，協助查找實體太多導致崩潰的原因

* 原理
	* 在所有Source引擎遊戲當中，當伺服器內的實體數量超過最大上限時，遊戲會崩潰 (上限根據每個遊戲決定)
		* 舉例: L4D1/2 只能容量2048的實體，如果超過會導致崩潰，提示:  ```ED_Alloc: no free edicts```
		* 凡舉武器、玩家、障礙物、物品、機關、殭屍、NPC、特效...，都是實體的一種, 會占用伺服器的空間
		* Source引擎大部分遊戲老舊，越新出的遊戲可有更多得實體上限
	* 此插件協助查看地圖當前所有實體的資訊與總數量
		* 能幫助服主或開發者快速瀏覽當前所有實體，並找出可能會導致伺服器崩潰的原因
		* 管理員輸入```!entlog```，產生文件報告記錄地圖當前所有實體，文件位於```logs/entity_limit_xxx.log```
		* 當伺服器內的實體總數量快要滿上限時，產生文件報告記錄地圖當前所有實體，文件位於```logs/entity_limit_xxx.log```

* <details><summary>指令中文介紹 (點我展開)</summary>

	* cfg/sourcemod/entity_limit_logger.cfg
		```php
		// 地圖載入十秒後開始計算地圖的所有實體
		entity_limit_logger_delay "10.0"

		// 當伺服器內的實體位子剩餘100個時 (快要滿上限)，產生log的文件記錄地圖當前所有實體
		entity_limit_logger_unsafe_left "100"
		```
</details>

* <details><summary>命令中文介紹 (點我展開)</summary>

	* **產生文件報告: logs/entity_limit_xxx.log (權限: ADMFLAG_ROOT)**
		```php
		sm_entlog
		sm_logent
		```

	* **重新計算地圖上每一個Classname的數量 (權限: ADMFLAG_ROOT)**
		```php
		sm_entsnap
		```
</details>