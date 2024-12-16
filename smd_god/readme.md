
# Description | 內容
Create a convar, so all players don't take damage

* Apply to | 適用於
    ```
    Any Source Game
    ```

* <details><summary>How does it work?</summary>

	* Set ```smd_god 1```, all players won't take damage
</details>

* Require | 必要安裝
<br/>None    

* <details><summary>ConVar | 指令</summary>

	* No autogenerate cfg
		```php
        // All alive players don't take any damage
        smd_god "0"
		```
</details>

* <details><summary>Command | 命令</summary>

	None
</details>

* <details><summary>Changelog | 版本日誌</summary>

	* v1.0 (2024-12-17)
		* Initial Release
</details>

- - - -
# 中文說明
創造一個指令，讓所有玩家無敵不受到任何傷害

* 原理
    * 管理員輸入```sm_cvar smd_god 1```，所有玩家都不會受到任何傷害

* 用意在哪?
    * 玩家不會受傷死亡，方便伺服器測試用



