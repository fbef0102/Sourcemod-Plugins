# Description | 內容
Server name with txt file (Support any language)

* Apply to | 適用於
    ```
    Any Source Game
    ```

* Image | 圖示
    * Dynamic Host Name (Support any language) - 可以有中文房名
    <br/>![smd_DynamicHostname_1](image/smd_DynamicHostname_1.jpg)

* <details><summary>How does it work?</summary>

    1. Install and launch server, file ```configs/hostname/server_hostname_xxxxx.txt``` will be auto-generated
        * ```xxxxx``` is server port
    2. Modify file
        ```php
        [TS] CS:S 混戰伺服器-測試服
        ```
    3. Write down plugin convar in cfg/server.cfg
        ```php
        //League notice displayed on server name (Empty=Disable)
        smd_current_mode "Zombie mod"
        ```
    4. The Server name will change on map change or server restart
        ```php
        [TS] CS:S 混戰伺服器-測試服 (Zombie mod)
        ```
        ![smd_DynamicHostname_2](image/smd_DynamicHostname_2.jpg)
</details>

* Require | 必要安裝
<br/>None

* <details><summary>ConVar | 指令</summary>

    * No cfg generated
        ```php
        // Text displayed after server name
        smd_current_mode ""
        ```
</details>

* <details><summary>Changelog | 版本日誌</summary>

    * v1.0 (2024-4-7)
        * Initial Release
</details>

- - - -
# 中文說明
伺服器房名可以寫中文的插件

* 原理
    * 伺服器房名只能寫英文，裝上這個插件之後，伺服器房名可以寫中文
    * 文件```configs/hostname/server_hostname.txt```是預設的房名

* <details><summary>改房名步驟</summary>

    1. 安裝插件後啟動伺服器，會自動產生文件 ```configs/hostname/server_hostname_xxxxxx.txt```
        * ```xxxxx```是伺服器的端口，也就是port
    
    2. 請打開並輸入房名 (可以寫中文)
        ```php
        [TS] CS:S 混戰伺服器-測試服
        ```

    3. 插件的指令寫入 cfg/server.cfg
        ```php
        //房名之後的模式介紹，不可以寫中文 (可以留白不寫)
        smd_current_mode "Zombie mod"
        ```
        
    4. 等待伺服器重啟或換圖之後，房名會變成
        ```php
        [TS] CS:S 混戰伺服器-測試服 (Zombie mod)
        ```
        ![smd_DynamicHostname_2](image/smd_DynamicHostname_2.jpg)
</details>