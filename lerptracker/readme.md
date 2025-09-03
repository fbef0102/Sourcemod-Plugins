# Description | 內容
Keep track of players' lerp settings
    
* Apply to | 適用於
    ```
    Any Source Game
    ```

* <details><summary>How does it work?</summary>

    * Display lerp when player joins team to play.
    * Kick player if lerp is illegal
    * If you don't know what is "lerp", please google it
</details>

* Require | 必要安裝
    1. [[INC] Multi Colors](https://github.com/fbef0102/L4D1_2-Plugins/releases/tag/Multi-Colors)

* <details><summary>ConVar | 指令</summary>

    * cfg/sourcemod/lerptracker.cfg
        ```php
        // Log changes to client lerp. 1=Log initial lerp and changes 2=Log changes only
        sm_log_lerp "1"

        // Announce client lerp. 1=Announce lerp and changes eveytime 2=Announce changes only
        sm_announce_lerp "1"

        // Fix Lerp values clamping incorrectly when interp_ratio 0 is allowed
        sm_fixlerp "1"

        // Kick players whose settings breach this Hard upper-limit for player lerps.
        sm_max_interp "0.5"

        // Display Style, 0 = default, 1 = team based
        sm_lerpstyle "1"

        // Minimum allowed lerp value, Force player to Spec if lower than Minimum
        sm_min_lerp "0.000"

        // Maximum allowed lerp value, Force player to Spec if greater than Maximum
        sm_max_lerp "0.1"
        ```
</details>

* <details><summary>Command | 命令</summary>

	* **List the Lerps of all players in game**
		```php
		sm_lerps
		```
</details>

* <details><summary>Changelog | 版本日誌</summary>

    * v1.2 (2025-9-3)
        * Update cvars

    * v1.1
        * Remake Code

    * Original
        * [ProdigySim/L4D2-Competitive-Framework](https://github.com/ProdigySim/L4D2-Competitive-Framework/blob/master/addons/sourcemod/scripting/lerpmonitor.sp)
</details>

- - - -
# 中文說明
顯示玩家的Lerp值

* 原理
    * 玩家加入隊伍時顯示lerp
    * 玩家的lerp不合法之時踢出伺服器
    * 不知道什麼是"lerp"，自行Google

* <details><summary>指令中文介紹 (點我展開)</summary>

    * cfg/sourcemod/lerptracker.cfg
        ```php
        // Logs文件如何記錄? 1=記錄玩家最初的lerp與改變時的lerp 2=記錄玩家改變時的lerp
        sm_log_lerp "1"

        // 聊天框如何顯示?. 1=每次顯示玩家的lerp與玩家改變lerp 2=只顯示玩家改變lerp
        sm_announce_lerp "1"

        // 為1時，當伺服器允許interp_ratio 0之時修復客戶端的lerp參數
        sm_fixlerp "1"

        // 玩家的lerp超過此數值之時，踢出伺服器
        sm_max_interp "0.5"

        // 顯示lerp的顏色, 0 = 白色, 1 = 隊伍顏色 (紅或藍)
        sm_lerpstyle "1"

        // 允許的最小lerp值, 當玩家比這數值低時將會被移至旁觀
        sm_min_lerp "0.000"

        // 允許的最大lerp值, 當玩家比這數值高時將會被移至旁觀
        sm_max_lerp "0.1"
        ```
</details>

* <details><summary>命令中文介紹 (點我展開)</summary>

	* **顯示所有玩家的Lerp**
		```php
		sm_lerps
		```
</details>
