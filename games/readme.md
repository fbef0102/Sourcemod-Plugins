# Description | 內容
Let's play a game, Duel!
    
* Apply to | 適用於
    ```
    Any Source Game
    ```

* <details><summary>How does it work?</summary>

    * ```!roll```: Roll a 6 sided die.
    * ```!coin```: Flip a coin.
    * ```!code```: Play a Da Vinci Code.
</details>

* Require | 必要安裝
    1. [[INC] Multi Colors](https://github.com/fbef0102/L4D1_2-Plugins/releases/tag/Multi-Colors)

* <details><summary>ConVar | 指令</summary>

    * cfg/sourcemod/games.cfg
        ```php
        // Time delay in seconds between allowed coinflips. Set at -1 if no delay at all is desired.
        coinflip_delay "1"
        ```
</details>

* <details><summary>Command | 命令</summary>

	* **Roll a x sided die.**
		```php
		sm_roll <X>
		sm_picknumber <X>
		```

	* **Flip a coin.**
		```php
		sm_coin
		sm_coinflip
		sm_cf
		sm_flip
		```

	* **Play a Da Vinci Code.**
		```php
		sm_code <0-100000>
		```
</details>

* <details><summary>Changelog | 版本日誌</summary>

    * v1.3
        * Initial Release
</details>

- - - -
# 中文說明
小遊戲，大家玩! Duel 決鬥!!

* 原理
    * ```!roll```: 擲骰子, 結果: 數字1~6
    * ```!coin```: 擲硬幣, 結果: 正面或反面
    * ```!code```: 終極密碼, 挑選一個數字, 其他人來猜猜看

* <details><summary>指令中文介紹 (點我展開)</summary>

    * cfg/sourcemod/games.cfg
        ```php
        // 投擲硬幣的冷卻時間. -1=無冷卻
        coinflip_delay "1"
        ```
</details>

* <details><summary>命令中文介紹 (點我展開)</summary>

	* **擲X面骰子**
		```php
		sm_roll <X>
		sm_picknumber <X>
		```

	* **擲硬幣**
		```php
		sm_coin
		sm_coinflip
		sm_cf
		sm_flip
		```

	* **終極密碼**
		```php
		sm_code <0-100000>
		```
</details>
