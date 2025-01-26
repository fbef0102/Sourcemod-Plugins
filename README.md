# Sourcemod-Plugins by Harry Potter
Plugins for most source engine games. Make server more fun, and more useful plugins for adm.

# Appreciate my work, you can [PayPal Donate](https://paypal.me/Harry0215?locale.x=zh_TW) me.
If you want any modify or request, free to use or pay me money to do it.
# Require
* [Sourcemod 1.11](https://www.sourcemod.net/downloads.php?branch=1.11-dev) (or newer)
* [Metamod 1.11](https://www.sourcemm.net/downloads.php?branch=1.11-dev) (or newer)

**[>>Click here to see my private plugin list<<](https://github.com/fbef0102/Game-Private_Plugin?tab=readme-ov-file#%E7%A7%81%E4%BA%BA%E6%8F%92%E4%BB%B6%E5%88%97%E8%A1%A8-private-plugins-list)**<br/>
**[>>點擊我查看更多私人插件<<](https://github.com/fbef0102/Game-Private_Plugin?tab=readme-ov-file#%E7%A7%81%E4%BA%BA%E6%8F%92%E4%BB%B6%E5%88%97%E8%A1%A8-private-plugins-list)**

# Source-Plugins
> Apply to most source engine games
> <br/>適用於大部份的Source引擎遊戲

* <b>[smd_DynamicHostname](/smd_DynamicHostname)</b>: Server name with txt file (Support any language)
    * 伺服器房名可以寫中文的插件
* <b>[smd_god](/smd_god)</b>: Create a convar, so all players don't take damage
    * 創造一個指令，讓所有玩家無敵不受到任何傷害
* <b>[smd_teleport_player](/smd_teleport_player)</b>: Teleport an alive player in game
    * 傳送玩家到其他玩家身上或準心上
* <b>[smd_restartmap_command](/smd_restartmap_command)</b>: Admin say !restartmap to restart current map 
    * 管理員輸入!restartmap能重新地圖關卡
* <b>[simple_chatprocessor](/simple_chatprocessor)</b>: Process chat and allows other plugins to manipulate chat.
    * 輔助插件，控制玩家在聊天窗口輸入的文字與顏色
* <b>[cannounce](/cannounce)</b>: Replacement of default player connection message, allows for custom connection messages
    * 顯示玩家進來遊戲或離開遊戲的提示訊息 (IP、國家、Steam ID 等等)
* <b>[smd_texture_manager_block](/smd_texture_manager_block)</b>: Kicks out clients who are potentially attempting to enable mathack
    * 遊戲中頻繁檢測每一位玩家並踢出試圖使用作弊指令的客戶
* <b>[sm_translator](/sm_translator)</b>: Translate chat message via Google API
    * 翻譯你的句子給其他玩家 (玩家對應的語言)
* <b>[helpmenu](/helpmenu)</b>: In-game Help Menu (Support Translation)
    * 輸入!helpmenu顯示選單，用來幫助玩家瞭解你的伺服器內容
* <b>[advertisements](/advertisements)</b>: Display advertisements
    * 廣告&公告欄插件，每隔一段時間於聊天框自動顯示一段公告內容
* <b>[bequiet](/bequiet)</b>: Please be Quiet! Block unnecessary chat or announcement.
    * 阻擋一些非必要提示的訊息在聊天框 (指令更改、名字更改)
* <b>[chat_responses](/chat_responses)</b>: Displays chat advertisements when specified text is said in player chat.
    * 玩家在聊天框輸入特地文字，伺服器會顯示廣告或提示
* <b>[GagMuteBanEx](/GagMuteBanEx)</b>: Gag & Mute & Ban - Ex
    * 封鎖/禁音/禁言-強化版
* <b>[games](/games)</b>: Let's play a game, Duel!
    * 小遊戲，大家玩! Duel 決鬥!!
* <b>[lerptracker](/lerptracker)</b>: Keep track of players' lerp settings
    * 顯示玩家的Lerp值
* <b>[lfd_noTeamSay](/lfd_noTeamSay)</b>: Redirecting all 'say_team' messages to 'say'
    * 沒有團隊聊天頻道只有公開聊天頻道
* <b>[linux_auto_restart](/linux_auto_restart)</b>: Make server restart (Force crash) when the last player disconnects from the server
    * 最後一位玩家離開伺服器之後自動關閉Server並重啟
* <b>[map-decals](/map-decals)</b>: Allows admins to place any decals into the map that are defined in the the config and save them permanently for each map.
    * 允許管理員將任何塗鴉放置在配置中定義的地圖中，並為每個地圖永久保存它們
* <b>[match_vote](/match_vote)</b>: Type !match/!load/!mode to vote a new mode
    * 輸入!match/!load/!mode投票執行cfg文件，用於更換模式或玩法
* <b>[server_loader](/server_loader)</b>: Executes cfg file on server startup
    * 開服只執行一次的cfg檔案
* <b>[firebulletsfix](/firebulletsfix)</b>: Fixes shooting/bullet displacement by 1 tick problems so you can accurately hit by moving.
    * 修復子彈擊中與伺服器運算相差 1 tick的延遲

# CSS-Plugins
> Apply to Counter-Strike: Source
> <br/>適用於絕對武力：次世代

* <b>[css_drop_weapon](/css_drop_weapon)</b>: Player can drop knife and HE Grenade, Smoke Grenade, Flash Bang
    * 可以丟棄手中的刀、閃光彈、高爆手榴彈、煙霧彈
* <b>[css_teleport_player](/css_teleport_player)</b>: Teleport an alive player in game
    * 傳送玩家到其他玩家身上或準心上
* <b>[css_respawn_player](/css_respawn_player)</b>: Allows players to be respawned at one's crosshair.
    * 復活死亡的玩家並傳送
* <b>[css_savechat_command](/css_savechat_command)</b>: Records player chat messages and commands to a file
    * 紀錄玩家的聊天紀錄與指令到文件裡

# NMRIH-Plugins
> Apply to No More Rooms In Hell
> <br/>適用於地獄已滿

* <b>[nmrih_giveweapons](/nmrih_giveweapons)</b>: Give weapons and items
    * 給予武器與物資
* <b>[nmrih_HUD](/nmrih_HUD)</b>: Display health, stamina, speed, infected status on hud
    * 顯示HUD在玩家的螢幕上: 血量、體力、感染狀態、速度...

# Scripting Compiler
* [sourcemod v1.11 compiler](https://www.sourcemod.net/downloads.php?branch=1.11-dev): scripting folder

# Others
* <b>[L4D1_2-Plugins](https://github.com/fbef0102/L4D1_2-Plugins)</b>: L4D1/2 general purpose and freaky-fun plugins.
* <b>[Sourcemod-Server](https://github.com/fbef0102/Sourcemod-Server)</b>: Setup your own sourcemod servers.
* <b>[Game-Private_Plugin](https://github.com/fbef0102/Game-Private_Plugin)</b>: Private Plugin List.