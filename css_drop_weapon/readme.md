
# Description | 內容
Player can drop knife and HE Grenade, Smoke Grenade, Flash Bang

* Video | 影片展示
<br/>None

* Image | 圖示
    <br/>![css_drop_weapon_1](image/css_drop_weapon_1.gif)

* Apply to | 適用於
	```
	Counter-Strike: Source
	```

* <details><summary>How does it work?</summary>

	* You can press G to drop all your weapons and items
</details>

* Require | 必要安裝
<br/>None

* <details><summary>ConVar | 指令</summary>

	* cfg\sourcemod\css_drop_weapon.cfg
		```php
        // 0=Plugin off, 1=Plugin on.
        css_drop_weapon_enable "1"
        
        // If 1, allow player to drop flash bang
        css_drop_weapon_drop_flashbang "1"

        // If 1, allow player to drop fragmentation grenades
        css_drop_weapon_drop_hegrenade "1"

        // If 1, allow player to drop knife
        css_drop_weapon_drop_knife "0"

        // If 1, allow player to drop smoke grenades
        css_drop_weapon_drop_smokegrenade "1"
		```
</details>

* <details><summary>Command | 命令</summary>

	None
</details>

* <details><summary>Changelog | 版本日誌</summary>

	* v1.0 (2023-3-3)
		* Initial Release
</details>

- - - -
# 中文說明
可以丟棄手中的刀、閃光彈、高爆手榴彈、煙霧彈

* 適用於
	```
	絕對武力：次世代
	```

* 原理
    * 按下"丟棄手中的物品"按鍵時，丟棄任何武器
    * 攜帶多個閃光彈、高爆手榴彈、煙霧彈時也可丟棄
    * 當扔出投閃光彈、高爆手榴彈、煙霧彈時，不能丟棄
    * 當使用刀進行攻擊動作時，不能丟棄

* <details><summary>指令中文介紹 (點我展開)</summary>

	* cfg\sourcemod\css_drop_weapon.cfg
		```php
        // 0=關閉插件, 1=啟動插件
        css_drop_weapon_enable "1"

        // 為1時，能丟棄閃光彈
        css_drop_weapon_drop_flashbang "1"

        // 為1時，能丟棄高爆手榴彈
        css_drop_weapon_drop_hegrenade "1"

        // 為1時，能丟棄刀子
        css_drop_weapon_drop_knife "0"

        // 為1時，能丟棄煙霧彈
        css_drop_weapon_drop_smokegrenade "1"
		```
</details>


