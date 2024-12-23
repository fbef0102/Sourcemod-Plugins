
# Description | 內容
Display health, stamina, speed, infected status on hud

* Apply to | 適用於
    ```
    No More Room in Hell
    ```

* Image | 圖示
    <br/>![nmrih_HUD_1](image/nmrih_HUD_1.jpg)
    
* <details><summary>How does it work?</summary>

    * Display health, stamina, infected status on hud
    * Type ```!speed``` to display your speed on hud
</details>

* Require | 必要安裝
<br/>None

* <details><summary>ConVar | 指令</summary>

    * cfg/sourcemod/nmrih_HUD.cfg
        ```php
        // 1 - Active the speedmeter for client by default, 0 = Disable the speedmeter for client by default
        nmrih_HUD_speedmeter "0"
        ```
</details>

* <details><summary>Command | 命令</summary>

    * **Enable/Disable Speed Hud**
        ```php
        sm_speed
        ```
</details>

* <details><summary>Translation Support | 支援翻譯</summary>

    ```
    English
    繁體中文
    简体中文
    ```
</details>

* <details><summary>Changelog | 版本日誌</summary>

    * v1.0h (2024-12-23)
        * Update translation
        * Improve code
    
    * [By clague](https://github.com/clague/plugin-source/blob/master/addons/sourcemod/scripting/HUD.sp)
</details>

- - - -
# 中文說明
顯示HUD在玩家的螢幕上: 血量、體力、感染狀態、速度...

* 適用於
    ```
    地獄已滿
    ```

* 圖示
    <br/>![zho/nmrih_HUD_1](image/zho/nmrih_HUD_1.jpg)

* 原理
    * 顯示HUD在玩家的螢幕上: 血量、體力、感染狀態
    * 輸入```!speed```顯示速度HUD

* <details><summary>指令中文介紹 (點我展開)</summary>

    * cfg/sourcemod/nmrih_HUD.cfg
        ```php
        // 1 - 自動幫玩家打開速度Hud, 0 = 不自動打開速度Hud，玩家需要手動輸入開啟
        nmrih_HUD_speedmeter "0"
        ```
</details>

* <details><summary>命令中文介紹 (點我展開)</summary>

    * **開/關 顯示速度HUD**
        ```php
        sm_speed
        ```
</details>



