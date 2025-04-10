# Description | 內容
Fixes shooting/bullet displacement by 1 tick problems so you can accurately hit by moving.

* Apply to | 適用於
    ```
    Counter-Strike: Source
    Counter-Strike: Go
    Left 4 Dead 2
    Left 4 Dead 1
    Team Fortress 2
    Day of Defeat: Source
    Nuclear Dawn
    Half-Life 2: Deathmatch
    NeoTokyo
    Insurgency
    No More Room in Hell
    ```

* Video | 影片展示
    1. [Huge CS:GO hitreg bug](https://www.youtube.com/watch?v=VPT0-CKODNc)
    2. [One bug from all valve games](https://www.youtube.com/watch?v=pr4EZ06mrpQ)

* Require | 必要安裝
<br/>None

* <details><summary>Changelog | 版本日誌</summary>

    * v1.1h (2024-8-26)
        * Improve code, [Credit](https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/firebulletsfix.sp)

    * v1.0h (2024-3-7)
        * Fixed physics objects are broken therefore tank hittables are flying totally random in l4d1/2

    * v1.0.2
        * [Original Plugin by Xutax_Kamay](https://github.com/XutaxKamay/firebulletsfix)
</details>

- - - -
# 中文說明
修復子彈擊中與伺服器運算相差 1 tick的延遲

* 原理
    * 請看上方 "影片展示"
    * 這是所有source引擎的遊戲都會有的bug (去你馬Valve)
    * 1 tick ≈ 0.033秒 (視伺服器tickrate決定)
    * L4D2貌似從2019 the last stand 更新之後有修復這個bug，但我沒感覺，如果官方真的已修復請通知