# Description | 內容
Display advertisements at regular intervals, with translation support

* Apply to | 適用於
	```
	Any Source Game
	```

* Image | 圖示
	* Display advertisements in chat box (顯示公告)
    <br/>![smd_advertisements_1](image/smd_advertisements_1.jpg)

* <details><summary>How does it work?</summary>

	* Display advertisements every 30 seconds, with multi language support
		* In Center text: Center message (does not support colors)
		* In Chatbox: Chat message (support colors)
		* In Hint: Hint message (does not support colors)
		* In Menu: Menu message (does not support colors)
	* Modify advertisements you want in [translations/smd_advertisements.phrases.txt](translations/smd_advertisements.phrases.txt)
		* Manual in this file, click for more details...
</details>

* Require | 必要安裝
    1. [[INC] Multi Colors](https://github.com/fbef0102/L4D1_2-Plugins/releases/tag/Multi-Colors)

* <details><summary>ConVar | 指令</summary>

	* cfg/sourcemod/smd_advertisements.cfg
		```php
		// 0=Plugin off, 1=Plugin on.
		smd_advertisements_enable "1"

		// How to display advertisement. 1=In center text, 2=In chat, 3=In Hint Box, 4=In Menu
		smd_advertisements_type "2"

		// Amount of seconds between advertisements.
		smd_advertisements_interval "30"

		// Display advertisement sound file (relative to to sound/, empty=disable)
		smd_advertisements_soundfile "ui/beepclear.wav"
		```
</details>

* Translation Support | 支援翻譯
	```
	translations/smd_advertisements.phrases.txt
	```

* <details><summary>Changelog | 版本日誌</summary>

	* v1.1h (2026-9-18)
		* Remake code
		* Display advertisements with translation support
		* Update cvars

	* v1.0h (2025-4-11)
		* Fixed error
		* Optimize code

	* v2.2.1 (2023-4-22)
		* Remake Code
		* Remove updater
		* Add multicolors to support l4d1, l4d2

	* Credits
		* [Original Plugin by DJ Tsunami](https://forums.alliedmods.net/showthread.php?t=155705)
</details>

- - - -
# 中文說明
每隔一段時間於聊天框自動顯示公告或是廣告，支援多國翻譯

* 原理
	* 伺服器每隔一段時間會自動顯示一段文字
		* 顯示於螢幕中央 (不支援顏色)
		* 顯示於聊天框 (支援顏色)
		* 顯示於螢幕下方黑底白字框 (不支援顏色)
		* 顯示於左邊菜單介面 (不支援顏色)
	* 可以自行決定想要顯示的內容，位於翻譯文件 [translations/smd_advertisements.phrases.txt](translations/smd_advertisements.phrases.txt)
		* 內有中文說明，可點擊查看

* 用意在哪? 
	* 打廣告
	* 顯示公告
	* 宣揚理念

* <details><summary>指令中文介紹 (點我展開)</summary>

	* cfg/sourcemod/smd_advertisements.cfg
		```php
		// 0=關閉插件, 1=啟動插件
		smd_advertisements_enable "1"

		// 公告顯示在哪. (1: 螢幕正中間, 2: 聊天框, 3: 黑底白字框, 4: 左邊菜單介面)
		smd_advertisements_type "2"

		// 相隔時間顯示公告 (秒)
		smd_advertisements_interval "30"

		// 顯示公告時，播放音效 (路徑相對於 sound　資料夾, 空=不播放)
		smd_advertisements_soundfile "ui/beepclear.wav"
		```
</details>