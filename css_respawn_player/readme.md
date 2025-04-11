# Description | 內容
Allows players to be respawned at one's crosshair.

* Apply to | 適用於
	```
	Counter-Strike: Source
	```

* Image | 圖示
<br/>![css_respawn_player_1](image/css_respawn_player_1.gif)

* <details><summary>How does it work?</summary>

	* Admins type ```!admin``` -> Player commands -> Player commands -> Respawn Player
	* Or ```!respawn```
</details>

* Require | 必要安裝
<br/>None

* <details><summary>ConVar | 指令</summary>

	* cfg/sourcemod/css_respawn_player.cfg
		```php
		// If 1, Add 'Respawn player' item in admin menu under 'Player commands' category
		css_respawn_player_adminmenu "1"

		// If 1, Give Kevlar Suit and a Helmet when repsawn player
		css_respawn_player_armor "1"

		// After respawn player, teleport player to 0=Crosshair, 1=Self (You must be alive).
		css_respawn_player_destination "0"

		// Respawn players with this loadout, separate by commas
		css_respawn_player_loadout "weapon_knife,weapon_glock,weapon_mp5navy"

		// If 1, Notify in chat and log action about respawn?
		css_respawn_player_showaction "1"
		```
</details>

* <details><summary>Command | 命令</summary>

	* **Respawn a player at your crosshair. Without argument - opens menu to select players (Adm required: ADMFLAG_BAN)**
		```php
		sm_respawn
		```
</details>

* <details><summary>Changelog | 版本日誌</summary>

	* v1.1 (2023-3-8)
		* Give Kevlar Suit and a Helmet when repsawn player

	* v1.0 (2023-3-3)
		* Initial Release
</details>

- - - -
# 中文說明
復活死亡的玩家並傳送

* 適用於
	```
	絕對武力：次世代
	```

* 原理
	* 管理員輸入```!admin``` -> 玩家指令 -> 復活玩家並傳送到準心上
	* 或輸入```!respawn```

* <details><summary>指令中文介紹 (點我展開)</summary>

	* cfg/sourcemod/css_respawn_player.cfg
		```php
		// 為1時，管理員菜單增加 "復活玩家" 選項
		css_respawn_player_adminmenu "1"

		// 為1時，復活時間時給予防彈背心與頭盔
		css_respawn_player_armor "1"

		// 復活玩家後，傳送玩家至 0=準心上, 1=自己身上 (必須活著).
		css_respawn_player_destination "0"

		// 復活玩家後，給予這些武器
		css_respawn_player_loadout "weapon_knife,weapon_glock,weapon_mp5navy"

		// 為1時，提示有人被復活
		css_respawn_player_showaction "1"
		```
</details>
