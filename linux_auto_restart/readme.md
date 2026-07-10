# Description | 內容
Make server restart (Force crash) when the last player disconnects from the server

* Apply to | 適用於
    ```
    Any Source Game
    ```

* Require | 必要安裝
<br/>None

* <details><summary>How does it work?</summary>

  * When the last player disconnects from the server, this plugin will force server crash itself.
  * This plugin does not restart your server, you need to use server management tools or linux system, which make server auto-restart if crash. For example:
	* Screen command in Linux
    * [seDirector](https://sedirector.net/) in Windows
  * Keep your server clean and fresh, get rid of laggy and huge memory usage
  * Unload [asherkin/Accelerator](https://forums.alliedmods.net/showthread.php?t=277703) or [MrPanica/accelerator](https://github.com/MrPanica/accelerator) extension automatically before crash. Avoid crash report spam.
</details>

* <details><summary>What is Accelerator extension?</summary>

	* Analyses crash reports to extract useful information and uploads the crash reports to the processing backend 
	* [How to install Accelerator Crash Report](https://github.com/fbef0102/Game-Private_Plugin/tree/main/Tutorial_%E6%95%99%E5%AD%B8%E5%8D%80/English/Server/Install_Other_File#accelerator-crash-report)
</details>

* <details><summary>Changelog | 版本日誌</summary>

	* v3.4 (2026-6-26)
		* Fixed server unables to unload Accelerator extension if players use other version of extension, example: MrPanica's accelerator

	* v3.3 (2024-12-7)
	* v3.2 (2024-11-30)
	* v3.1 (2024-10-26)
		* Optimize Code
		
	* v3.0 (2024-3-19)
		* Add log

	* v2.9 (2024-2-27)
	* v2.8 (2024-1-21)
		* Optimize Code

	* v2.4 (2023-3-29)
		* Auto detect Accelerator extension and unload extension before shutdown
		* Remove Cvar

	* v1.0
		* Initial Release
</details>

- - - -
# 中文說明
最後一位玩家離開伺服器之後自動關閉Server並重啟

* 原理
	* 當最後一位玩家離開伺服器之後過一段時間，如果還是沒有人那麼插件會強制關閉伺服器
    * 這插件不會重啟你的伺服器，而是強制伺服器崩潰而已 (就是強制結束伺服器的意思)
	* 使用一些開服管理工具，伺服器被強制結束時會自己自動重新啟動，譬如:
		* Linux系統使用screen指令
		* Windows系統使用[seDirector](https://sedirector.net/)...等開服工具
	* 強制結束伺服器之前卸載[asherkin的Accelerator](https://forums.alliedmods.net/showthread.php?t=277703)或[MrPanica的accelerator](https://github.com/MrPanica/accelerator)，避免重複產生崩潰日誌

* 用意在哪?
    * 此插件用來配合一些軟體或腳本開服，伺服器被強制結時會自己自動重新啟動
    * 適合7天24小時全天候開服的伺服器，持續讓你的伺服器重新啟動保持新的狀態，避免開服過久導致卡頓與lag

* Accelerator 是什麼?
	* 這是一種檢測伺服器崩潰並且產生日誌的實用工具
	* [安裝accelerator的崩潰檢測工具](https://github.com/fbef0102/Game-Private_Plugin/tree/main/Tutorial_%E6%95%99%E5%AD%B8%E5%8D%80/Chinese_%E7%B9%81%E9%AB%94%E4%B8%AD%E6%96%87/Server/%E5%AE%89%E8%A3%9D%E5%85%B6%E4%BB%96%E6%AA%94%E6%A1%88%E6%95%99%E5%AD%B8#%E5%AE%89%E8%A3%9Daccelerator%E7%9A%84%E5%B4%A9%E6%BD%B0%E6%AA%A2%E6%B8%AC%E5%B7%A5%E5%85%B7)