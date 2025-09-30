# Description | 內容
Translate chat message via Google API

* Apply to | 適用於
    ```
    Any Source Game
    ```

* Image | 圖示
    <br/>![sm_translator_1](image/sm_translator_1.jpg)
    <br/>![sm_translator_2](image/sm_translator_2.jpg)
    <br/>![sm_translator_3](image/sm_translator_3.jpg)

* <details><summary>How does it work?</summary>

    * Display menu when new player joins server 
        * Choose "Yes, translate my words to other player" -> Your chat messages will be translated into other player
    * If player A's Steam language is set to **Russian** and the server language is **English**, when player A types text in the chatbox
        * Text will be translated into the server language (**English**), only player A can see.
        * If player B's Steam language is set to **French**, player B will see French text.
        * If player C's Steam language is set to **Japanese**, player C will see Japanese text.
        * If player D's Steam language is set to **Russian**, player D will not see the translation (unless player A's text is not Russian).
    * Your words will be
        * Translated into server language (English), only you will see
        * Translated into other players depends on their steam platform language (Chinese, Russian...)
    * You can check the server language on ```addons/sourcemod/configs/core.cfg``` (Do not modify)
        ```
        "ServerLang"    "en"
        ```

    * Note 
        * The translation is using Google Translation API, it will auto detect your language
        * May not working if Google is blocked in your Country/Region
        * Google may detect wrong language
        * If sourcemod does not support your language, you will only see the english
            * check ```addons/sourcemod/configs/languages.cfg```
</details>

* Require | 必要安裝
    1. [[INC] Multi Colors](https://github.com/fbef0102/L4D1_2-Plugins/releases/tag/Multi-Colors)
    2. [[INC] sm-json](https://github.com/clugg/sm-json)
    3. [SteamWorks](https://github.com/hexa-core-eu/SteamWorks/releases)

* <details><summary>ConVar | 指令</summary>

    * cfg/sourcemod/sm_translator.cfg
        ```php
        // 0=Plugin off, 1=Plugin on.
        sm_translator_enable "1"

        // When new player connects
        // 0=Display menu to ask if player 'yes' or 'no'
        // 1=Auto enable translator for all players + Disable menu
        sm_translator_auto "1"

        // If 1, use CookiesCached to save player settings. No need to select 'yes' or 'no' menu if rejoin server next time.
        sm_translator_save_cookie "1"
        ```
</details>

* <details><summary>Command | 命令</summary>

    * **Open translator menu**
        ```php
        sm_translator
        ```

    * **Display other players' translations off/on**
        ```php
        sm_showtranslate
        ```
</details>

* <details><summary>Changelog | 版本日誌</summary>

    * v1.8h (2025-10-1)
    * v1.7h (2025-9-23)
        * Use google api to auto detect langauge
        * 繁體中文與簡體中文還是會互相翻譯

    * v1.6h (2025-8-30)
        * Update cvars, cmds, translation

    * v1.5h (2025-1-7)
        * Use cookie to save client setting
        * Update cvars

    * v1.4h (2024-9-22)
        * Block chat translation if different team
        * Update translation

    * v1.3h (2024-9-21)
    * v1.2h (2024-9-20)
        * Update cvars

    * v1.1h (2024-9-9)
        * Fixed memory leak

    * v1.0h (2024-6-16)
        * Use Google Translation API
        * Add json inc
        * Update translation

    * v1.0
        * [Original Plugin by Franc1sco](https://forums.alliedmods.net/showthread.php?t=306279)
</details>

- - - -
# 中文說明
翻譯你的句子給其他玩家 (玩家對應的語言)

* 圖示
    <br/>![zho/sm_translator_1](image/zho/sm_translator_1.jpg)

* 原理
    * 進入伺服器之後顯示選單 -> 選擇"好..." -> 你打字聊天的內容將會被翻譯
    * 假設A玩家的steam平台設置的語言是**繁體中文**，伺服器語言是**英文**，A玩家在聊天框打字的內容會
        * 翻譯成伺服器語言 (**英文**)，給A玩家自己看
        * B玩家的steam平台設置的語言是**法文**，那B玩家會看到法文
        * C玩家的steam平台設置的語言是**日文**，那C玩家會看到日文
        * D玩家的steam平台設置的語言是**繁體中文**，那D玩家不會看到翻譯 (除非A玩家輸入的文字不是繁體中文)
        * E玩家的steam平台設置的語言是**簡體中文**，那E玩家會看到翻譯
    * 伺服器語言預設是英文，可於 ```addons/sourcemod/configs/core.cfg``` 查看 (最好不要修改)
        ```
        "ServerLang"    "en"
        ```

* 注意事項
    * 使用的是Google提供的API翻譯，所以可能翻譯得不正確
    * 如果你所在的地區無法上Google網站，可能無法使用此插件
    * Google的自動可能會檢測到錯誤的語言
    * 如果Sourcemod不支援你的語言，你只會看到英文翻譯
        * 查看Sourcemod 支援的語言列表: ```addons/sourcemod/configs/languages.cfg```
    * 玩家看到的語言翻譯取決於他們的steam平台設置的語言

* <details><summary>指令中文介紹 (點我展開)</summary>

    * cfg/sourcemod/sm_translator.cfg
        ```php
        // 1=開啟插件. 0=關閉插件
        sm_translator_enable "1"

        // 當玩家進來伺服器時
        // 0=彈出選單詢問玩家是否自動翻譯
        // 1=自動幫所有玩家翻譯+選單不能使用
        sm_translator_auto "1"

        // 為1時，使用 CookiesCached 儲存玩家設定. 意思是說，下次玩家進服後不需要再顯示選單
        sm_translator_save_cookie "1"
        ```
</details>

* <details><summary>命令中文介紹 (點我展開)</summary>

    * **打開選單**
        ```php
        sm_translator
        ```

    * **開關顯示其他人的翻譯語句**
        ```php
        sm_showtranslate
        ```
</details>