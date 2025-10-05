# Description | 內容
Block family share accounts which does not own the game

* Apply to | 適用於
    ```
    Any Source Game
    ```

* Require | 必要安裝
    1. [SteamWorks](https://github.com/hexa-core-eu/SteamWorks/releases)

* <details><summary>How does it work?</summary>

    * If player does not own the game and join server (Use steam family share)
        * Kick player and ban
        * Log record in [logs/familyshare_manager.log](logs/familyshare_manager.log)
    * Whitelist list, player in this list will not be detected: [configs/familyshare_whitelist.ini](configs/familyshare_whitelist.ini)
</details>

* <details><summary>Known Conflicts</summary>
    
    If you don't use any of these files at all, no need to worry about conflicts.
    1. [lakwsh/l4dtoolz](https://github.com/lakwsh/l4dtoolz/releases): SteamWorks would stop working if set ```sv_steam_bypass 1```
</details>

* <details><summary>ConVar | 指令</summary>

    * cfg/sourcemod/familyshare_manager.cfg
        ```php
        // 0=Plugin off, 1=Plugin on.
        familyshare_manager_enable "1"

        // Players with these flags will be ignored (Empty = Everyone, -1: Nobody)
        familyshare_manager_ignore_admin_flag "z"

        // Ban duration (Mins) (0=Permanent, -1: Kick only)
        familyshare_manager_ban_time "1440"
        ```
</details>

* <details><summary>Command | 命令</summary>

    * **Reload the whitelist: configs/familyshare_whitelist.ini (Access: ADMFLAG_ROOT)**
        ```php
        sm_reloadlist
        ```

    * **Add a player to the whitelist (Access: ADMFLAG_ROOT)**
        ```php
        sm_addtolist <SteamID 64>
        ```

    * **Remove a player from the whitelist (Access: ADMFLAG_ROOT)**
        ```php
        sm_removefromlist <SteamID 64>
        ```

    * **View current whitelist (Access: ADMFLAG_ROOT)**
        ```php
        sm_displaylist
        ```
</details>

* Translation Support | 支援翻譯
    ```
    translations/familyshare_manager.phrases.txt
    ```

* <details><summary>Changelog | 版本日誌</summary>

    * v1.2h (2025-10-5)
        * Remake code, convert code to latest syntax
        * Add cvars, cmds, translation
        * Use steam 64 ID instea of Steam ID (More accurate)
        * Add ban minutes and kick message
        * Add log record
        * Remove updater

    * Original & Credit
        * [Original plugin by s (+bonbon, 11530)](https://forums.alliedmods.net/showthread.php?t=293927)
</details>

- - - -
# 中文說明
封鎖使用家庭共享沒有真的購買遊戲的帳戶進來伺服器

* 原理
    * 如果玩家沒有購買遊戲卻使用家庭分享遊玩
        * 進入伺服器後會被踢出去
        * 寫紀錄於文件: [logs/familyshare_manager.log](logs/familyshare_manager.log)
    * 設置白名單列表，在此名單內的玩家不會被檢測: [configs/familyshare_whitelist.ini](configs/familyshare_whitelist.ini)

* 用意在哪?
    * 防止玩家開小號

* <details><summary>會衝突的檔案</summary>
    
    如果沒安裝以下檔案就不需要擔心衝突
    1. [lakwsh/l4dtoolz](https://github.com/lakwsh/l4dtoolz/releases): 如果設置 ```sv_steam_bypass 1```, SteamWorks會停止運作
</details>

* <details><summary>指令中文介紹 (點我展開)</summary>

    * cfg/sourcemod/familyshare_manager.cfg
        ```php
        // 0=關閉插件, 1=啟動插件
        familyshare_manager_enable "1"

        // 擁有這些權限的玩家，不會被檢測 (留白 = 任何人都能, -1: 無人)
        familyshare_manager_ignore_admin_flag "z"

        // 封鎖時間，單位是分鐘 (0=永久封鎖, -1: 只踢出遊戲)
        familyshare_manager_ban_time "1440"
        ```
</details>

* <details><summary>命令中文介紹 (點我展開)</summary>

    * **重載白名單: configs/familyshare_whitelist.ini (權限: ADMFLAG_ROOT)**
        ```php
        sm_reloadlist
        ```

    * **增加SteamID 64到白名單上 (權限: ADMFLAG_ROOT)**
        ```php
        sm_addtolist <SteamID 64>
        ```

    * **白名單上移除SteamID 64 (權限: ADMFLAG_ROOT)**
        ```php
        sm_removefromlist <SteamID 64>
        ```

    * **查看目前的白名單列表 (權限: ADMFLAG_ROOT)**
        ```php
        sm_displaylist
        ```
</details>
