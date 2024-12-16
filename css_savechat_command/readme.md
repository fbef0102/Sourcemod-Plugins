# Description | 內容
Records player chat messages and commands to a file

* Apply to | 適用於
	```
	Counter-Strike: Source
	```

* <details><summary>How does it work?</summary>

	* Records player chat messages and commands to a file
    * File: ```sourcemod\logs\chat\server_xxxxx_chat_yy_mm_dd.txt```
        * ```xxxxx``` is server port
        * ```yy``` is year
        * ```mm``` is month
        * ```dd``` is day
</details>

* Require | 必要安裝
<br/>None

* <details><summary>ConVar | 指令</summary>

    * cfg\sourcemod\savechat.cfg
        ```php
        // 0=Plugin off, 1=Plugin on.
        css_savechat_command_enable "1"
        
        // If 1, Record and save console commands.
        css_savechat_command_cosole_command "1"
        ```
</details>

* <details><summary>Command | 命令</summary>

    None
</details>

* <details><summary>Changelog | 版本日誌</summary>

    * v1.2 (2024-4-7)
        * Optimize code and improve performance

    * v1.1 (2023-3-4)
        * Comamnd Filter

    * v1.0 (2023-3-3)
        * Initial Release
</details>


- - - -
# 中文說明
紀錄玩家的聊天紀錄到文件裡

* 適用於
	```
	絕對武力：次世代
	```
    
* 原理
    * 當伺服器內玩家打字聊天時，將記錄玩家的對話到文件裡
    * 當伺服器內玩家在遊戲控制台輸入指令時，將記錄指令到文件裡
    * 會記錄玩家當下的IP、時間、Steam ID
    * 文件: ```sourcemod\logs\chat\server_xxxxx_chat_yy_mm_dd.txt```
        * ```xxxxx``` 是伺服器的端口，也就是port
        * ```yy``` 是年份
        * ```mm``` 是月份
        * ```dd``` 是日期

* 用意在哪?
    * 拿來抓鬼、看誰他馬在講管理員壞話或抱怨伺服器
    * 當玩家有吵架或比賽作弊爭議時，方便有證據檢舉
    * 看哪個混帳在控制台輸入指令導致伺服器崩潰或卡頓

* <details><summary>指令中文介紹 (點我展開)</summary>

    * cfg\sourcemod\savechat.cfg
        ```php
        // 0=關閉插件, 1=啟動插件
        css_savechat_command_enable "1"
        
        // 為1時，玩家在遊戲控制台輸入指令時，將記錄到文件裡
        css_savechat_command_cosole_command "1"
        ```
</details>