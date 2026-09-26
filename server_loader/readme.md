# Description | 內容
Executes cfg file on server startup only one time

* Apply to | 適用於
	```
	Any Source Game
	```

* <details><summary>How does it work?</summary>

	* Automatically executes a single cfg file once after the server starts up:
		* ```cfg/server_loader.cfg```
	* When the server starts up or changes maps (including restarts), the order in which SourceMod executes cfgs is:
		* ```cfg/autoexec.cfg``` (executed only once on server startup)
		* -> ```cfg/server.cfg```
		* -> CFG files of all plugins inside the ```cfg/sourcemod``` folder
		* -> (After 5 seconds) ```cfg/server_loader.cfg``` (Added by this plugin, forced to execute only once)
	* When the map changes or the server restarts, the order in which SourceMod executes cfgs is:
		* cfg/server.cfg
		* -> CFG files of all plugins inside the cfg/sourcemod folder
	* Purpose / Why need this plugin?
		* Some cvars or cmds only need to be configured once when the server starts and are not suitable to be placed in ```cfg/server.cfg``` or ```cfg/autoexec.cfg```
		* For example, suppose you want to modify a plugin cvar named ```l4d2_sv_slots```.
		* If you put it in cfg/server.cfg, it will cause the cvar ```l4d2_sv_slots``` to be overwritten every time the map changes.
		* If you put it in cfg/autoexec.cfg, the server hasn't loaded all plugins yet, so it cannot overwrite the cvar ```l4d2_sv_slots```.
</details>

* Require | 必要安裝
<br/>None

* Directory Structure | 檔案結構
	```
	/
	├── addons/sourcemod
	│		├── plugins/
	│		│	└── server_loader.smx	# Compiled plugin | 已編譯的插件檔案
	│		└── scripting/
	│			└── server_loader.sp	# Source code | 源碼
	└── cfg/
		└── server_loader.cfg			# Execute only one time | 只會執行一次的文件
	```

* <details><summary>Changelog | 版本日誌</summary>

	* v1.1h (2026-9-22)
		* Force to set official cvar "sv_hibernate_when_empty" 0 until cfg is executed in l4d1/2

	* v1.0h (2025-11-21)
		* Support any source game

	* v1.3 (2023-2-21)
		* Support L4D1

	* v1.2 (2023-2-4)
		* Initial Release
</details>

- - - -
# 中文說明
開服只執行一次的cfg檔案

* 原理
	* 啟動伺服器之後自動執行一個cfg檔案，只會執行一次
		* ```cfg/server_loader.cfg```
	* 當伺服器啟動或是地圖變更(包含重啟)時，Sourcemod執行cfg的順序如下
		* ```cfg/autoexec.cfg``` (開服只會執行一次)
		* ->```cfg/server.cfg```
		* -> ```cfg/sourcemod```資料夾內所有插件的cfg 
		* (五秒後)-> ```cfg/server_loader.cfg``` (本插件新增，強制只會執行一次)
	* 當地圖變更或是重啟時，Sourcemod執行cfg的順序如下
		* ```cfg/server.cfg```
		* -> ```cfg/sourcemod```資料夾內所有插件的cfg

* 用意在哪?
	* 有些指令只需要伺服器一開始設定一次就行了，不適合寫在```cfg/server.cfg```與```cfg/autoexec.cfg```
		* 譬如你想要修改插件的指令名為```l4d2_sv_slots```
		* 如果寫在```cfg/server.cfg```，會導致每次地圖變更時會覆蓋指令```l4d2_sv_slots```
		* 如果寫在```cfg/autoexec.cfg```，伺服器還沒載入所有插件，無法覆蓋指令```l4d2_sv_slots```