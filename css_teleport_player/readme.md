# Description | 內容
Teleport an alive player in game

* Image | 圖示
<br/>![css_teleport_player_1](image/css_teleport_player_1.gif)

* Apply to | 適用於
	```
	Counter-Strike: Source
	```

* <details><summary>How does it work?</summary>

	* Admins type ```!admin``` -> Player commands -> Teleport Player
	* Or ```!tp```, ```sm_teleport```
</details>

* Require | 必要安裝
<br/>

* <details><summary>ConVar | 指令</summary>

	* cfg/sourcemod/css_teleport_player.cfg
		```php
		// If 1, Add 'Teleport player' item in admin menu under 'Player commands' category
		css_teleport_playeradminmenu "1"
		```
</details>

* <details><summary>Command | 命令</summary>

	* **Open 'Teleport player' menu (Adm required: ADMFLAG_BAN)**
		```php
		sm_teleport
		sm_tp
		```
</details>

* <details><summary>Changelog | 版本日誌</summary>

	* v1.0 (2023-3-3)
		* Initial Release
</details>

- - - -
# 中文說明
傳送玩家到其他玩家身上或準心上

* 適用於
	```
	絕對武力：次世代
	```

* 原理
	* 管理員輸入```!admin``` -> 玩家指令 -> 傳送玩家
	* 或```!teleport```、```!tp```
