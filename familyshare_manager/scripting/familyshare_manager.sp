#pragma semicolon 1
#pragma newdecls required

#include <SteamWorks> //https://github.com/hexa-core-eu/SteamWorks/releases, it is dead in l4d1
#include <sourcemod>
#define PLUGIN_VERSION			"1.2h-2025/10/5"
#define PLUGIN_NAME			    "familyshare_manager"
#define DEBUG 0

public Plugin myinfo =
{
    name = "Family Share Manager",
    author = "s (+bonbon, 11530), HarryPotter",
    description = "Whitelist or ban family shared accounts",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?t=293927"
};

#define MAX_STEAMID_LENGTH 21
#define MAX_COMMUNITYID_LENGTH 18 

#define CVAR_FLAGS                    FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION     FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY

ConVar g_hCvarEnable,
    g_hCvar_IgnoreAdmins, g_hCvar_BanTime;
bool g_bCvarEnable;
char g_sCvar_IgnoreAdmins[16];
int g_iCvar_BanTime;

char g_sWhitelist[PLATFORM_MAX_PATH];
StringMap g_hWhitelistTrie;

public void OnPluginStart()
{
    LoadTranslations("familyshare_manager.phrases");

    g_hWhitelistTrie = new StringMap();

    g_hCvarEnable 		    = CreateConVar( PLUGIN_NAME ... "_enable",              "1",   "0=Plugin off, 1=Plugin on.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_IgnoreAdmins    = CreateConVar( PLUGIN_NAME ... "_ignore_admin_flag",   "z",    "Players with these flags will be ignored (Empty = Everyone, -1: Nobody)", FCVAR_NOTIFY);
    g_hCvar_BanTime         = CreateConVar( PLUGIN_NAME ... "_ban_time",            "1440", "Ban duration (Mins) (0=Permanent, -1: Kick only)", FCVAR_NOTIFY, true, 0.0);
    CreateConVar(                           PLUGIN_NAME ... "_version",             PLUGIN_VERSION, PLUGIN_NAME ... " Plugin Version", CVAR_FLAGS_PLUGIN_VERSION);
    AutoExecConfig(true,                    PLUGIN_NAME);

    GetCvars();
    g_hCvarEnable.AddChangeHook(ConVarChanged_Cvars);
    g_hCvar_IgnoreAdmins.AddChangeHook(ConVarChanged_Cvars);
    g_hCvar_BanTime.AddChangeHook(ConVarChanged_Cvars);

    BuildPath(Path_SM, g_sWhitelist, sizeof(g_sWhitelist), "configs/familyshare_whitelist.ini");

    RegAdminCmd("sm_reloadlist", command_reloadWhiteList, ADMFLAG_ROOT, "Reload the whitelist: configs/familyshare_whitelist.ini");
    RegAdminCmd("sm_addtolist", command_addToList, ADMFLAG_ROOT, "Add a player to the whitelist, sm_addtolist <SteamID 64>");
    RegAdminCmd("sm_removefromlist", command_removeFromList, ADMFLAG_ROOT, "Remove a player from the whitelist, sm_removefromlist <SteamID 64>");
    RegAdminCmd("sm_displaylist", command_displayList, ADMFLAG_ROOT, "View current whitelist");
}

//Cvars-------------------------------

void ConVarChanged_Cvars(ConVar hCvar, const char[] sOldVal, const char[] sNewVal)
{
	GetCvars();
}

void GetCvars()
{
    g_bCvarEnable = g_hCvarEnable.BoolValue;
    g_hCvar_IgnoreAdmins.GetString(g_sCvar_IgnoreAdmins, sizeof(g_sCvar_IgnoreAdmins));
    g_iCvar_BanTime = g_hCvar_BanTime.IntValue;
}

public void OnConfigsExecuted()
{
    parseList(false);
}

Action command_removeFromList(int client, int args)
{
    File hFile = OpenFile(g_sWhitelist, "a+");

    if(hFile == null)
    {
        LogError("[Family Share Manager] Critical Error: hFile is Invalid. --> command_removeFromList");
        ReplyToCommand(client, "[Family Share Manager] Plugin has encountered a critial error with the list file.");
        delete hFile;
        return Plugin_Handled;
    }

    if(args == 0)
    {
        ReplyToCommand(client, "[Family Share Manager] Invalid Syntax: sm_removefromlist <steam id>");
        return Plugin_Handled;
    }

    char steamid[128]; char playerSteam[32];
    GetCmdArgString(playerSteam, sizeof(playerSteam));

    StripQuotes(playerSteam);
    TrimString(playerSteam);
  
    bool found = false;
    ArrayList fileArray = CreateArray(32);

    while(!hFile.EndOfFile() && hFile.ReadLine(steamid, sizeof(steamid)))
    {
        if(strlen(steamid) < 1 || IsCharSpace(steamid[0])) continue;

        ReplaceString(steamid, sizeof(steamid), "\n", "", false);

        ReplyToCommand(client, "%s - %s", steamid, playerSteam);
        //Not found, add to next file.
        if(!StrEqual(steamid, playerSteam, false))
        {
            fileArray.PushString(steamid);
        }

        //Found, remove from file.
        else
        {
            found = true;
        }
    }

    delete hFile;

    //Delete and rewrite list if found..
    if(found)
    {
        DeleteFile(g_sWhitelist);
        File newFile = OpenFile(g_sWhitelist, "w");

        if(newFile == null)
        {
            LogError("[Family Share Manager] Critical Error: newFile is Invalid. --> command_removeFromList");
            ReplyToCommand(client, "[Family Share Manager] Plugin has encountered a critial error with the list file.");
            return Plugin_Handled;
        }

        ReplyToCommand(client, "[Family Share Manager] Found Steam ID 64: %s, removing from list...", playerSteam);

        newFile.WriteLine("// whitelist for familyshare_manager, steamid 64 only");
        newFile.WriteLine("// 寫在這裡的名單將不會被檢測, 請只寫steamid 64");

        for(int i = 0; i < GetArraySize(fileArray); i++)
        {
            char writeLine[32];
            fileArray.GetString(i, writeLine, sizeof(writeLine));
            newFile.WriteLine(writeLine);
        }

        delete newFile;
        delete fileArray;
        parseList(false);
        return Plugin_Handled;
    }
    else ReplyToCommand(client, "[Family Share Manager] Steam ID 64: %s not found, no action taken.", playerSteam);
    return Plugin_Handled;
}

Action command_addToList(int client, int args)
{
    File hFile = OpenFile(g_sWhitelist, "a+");
    
    //Argument Count:
    switch(args)
    {
        //Create Player List:
        case 0:
        {
            if(client == 0)
            {
                ReplyToCommand(client, "sm_addtolist <SteamID 64>");
                return Plugin_Handled;
            }

            Menu playersMenu = new Menu(playerMenuHandle);
            for(int i = 1; i <= MaxClients; i++)
            {
                if(IsClientAuthorized(i) && i != client)
                {
                    playersMenu.SetTitle("Viewing all players...");

                    char formatItem[2][32];
                    Format(formatItem[0], sizeof(formatItem[]), "%i", GetClientUserId(i));
                    Format(formatItem[1], sizeof(formatItem[]), "%N", i);

                    //Adds menu item per player --> Client User ID, Display as Username.
                    playersMenu.AddItem(formatItem[0], formatItem[1]);
                }
            }

            playersMenu.ExitButton = true;
            playersMenu.Pagination = 7;
            playersMenu.Display(client, MENU_TIME_FOREVER);

            PrintToChat(client, "[Family Share Manager] Displaying players menu...");

            delete hFile;
            return Plugin_Handled;
        }

        //Directly write Steam ID:
        default:
        {
            char steamid[32];
            GetCmdArgString(steamid, sizeof(steamid));

            StripQuotes(steamid);
            TrimString(steamid);

            if(StrContains(steamid, "STEAM_", false) >= 0)
            {
                ReplyToCommand(client, "[Family Share Manager] Invalid Input - Not a Steam 64 ID. (XXXXXXXX)");
                delete hFile;
                return Plugin_Handled;
            }

            if(hFile == INVALID_HANDLE)
            {
                LogError("[Family Share Manager] Critical Error: hFile is Invalid. --> command_addToList");
                ReplyToCommand(client, "[Family Share Manager] Plugin has encountered a critial error with the list file.");
                delete hFile;
                return Plugin_Handled;
            }

            bool bTemp = false;
            if(g_hWhitelistTrie.GetValue(steamid, bTemp))
            {
                ReplyToCommand(client, "[Family Share Manager] %s already exists in the list file", steamid);
                delete hFile;
                return Plugin_Handled;
            }

            hFile.WriteLine(steamid);
            ReplyToCommand(client, "[Family Share Manager] Successfully added %s to the list.", steamid);
            delete hFile;
            parseList(false);
            return Plugin_Handled;
        }
    }
}

int playerMenuHandle(Menu playerMenu, MenuAction action, int client, int menuItem)
{
    if(action == MenuAction_Select) 
    {   
        //Should be our Client's User ID.
        char menuItems[32]; 
        playerMenu.GetItem(menuItem, menuItems, sizeof(menuItems));

        int target = GetClientOfUserId(StringToInt(menuItems));
        
        //Invalid UserID/Client Index:
        if(!target)
        {
            LogError("[Family Share Manager] Critical Error: Invalid Client of User Id --> playerMenuHandle");
            delete playerMenu;
            return 0;
        }

        char steamid[32];
        GetClientAuthId(target, AuthId_SteamID64, steamid, sizeof(steamid));

        StripQuotes(steamid);
        TrimString(steamid);

        File hFile = OpenFile(g_sWhitelist, "a+");
        if(hFile == null)
        {
            LogError("[Family Share Manager] Critical Error: hFile is Invalid. --> playerMenuHandle");
            PrintToChat(client, "[Family Share Manager] Plugin has encountered a critial error with the list file.");
            delete hFile;
            return 0;
        }

        hFile.WriteLine(steamid);
        PrintToChat(client, "[Family Share Manager] Successfully added %s (%N) to the list.", steamid, target);
        delete hFile;
        parseList(false);
        return 0;
    }

    else if(action == MenuAction_End)
    {
        delete playerMenu;
    }

    return 0;
}

Action command_displayList(int client, int args)
{
    char auth[128];
    File hFile = OpenFile(g_sWhitelist, "a+");

    while(!hFile.EndOfFile() && hFile.ReadLine(auth, sizeof(auth)))
    {
        TrimString(auth);
        StripQuotes(auth);

        if(strlen(auth) < 1) continue;
        if(strncmp(auth, "//", 2, false) == 0) continue;
        ReplaceString(auth, sizeof(auth), "\n", "", false);

        if(StrContains(auth, "STEAM_", false) != -1)
        {
            if(!client) return Plugin_Handled;
            PrintToChat(client, "%s", auth); 
        }
    }

    delete hFile;
    return Plugin_Handled;
}

Action command_reloadWhiteList(int client, int args)
{
    ReplyToCommand(client, "[Family Share Manager] Rebuilding whitelist...");
    parseList(true, client);
    return Plugin_Handled;
}

void parseList(bool notify, int client = 0)
{
    delete g_hWhitelistTrie;
    g_hWhitelistTrie = new StringMap();

    char auth[128];
    File hFile = OpenFile(g_sWhitelist, "a+");

    while(!hFile.EndOfFile() && hFile.ReadLine(auth, sizeof(auth)))
    {
        TrimString(auth);
        StripQuotes(auth);

        if(strlen(auth) < 1) continue;
        if(strncmp(auth, "//", 2, false) == 0) continue;

        g_hWhitelistTrie.SetValue(auth, true, true);
    }

    if(notify)
    {
        if(client == 0) ReplyToCommand(client, "[Family Share Manager] Rebuild complete!");
        else PrintToChat(client, "[Family Share Manager] Rebuild complete!");
    }

    delete hFile;
}

public void OnClientPostAdminCheck(int client)
{
}

int GetClientFromSteamID(int authid)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i))
		{
			int tmp = GetSteamAccountID(i);
			if(tmp && tmp == authid)
			{
				return i;
			}
		}
	}

	return 0;
}

public void SteamWorks_OnValidateClient(int ownerauthid, int authid)
{
    if(!g_bCvarEnable) return;

    int client = GetClientFromSteamID(authid);
    if(client <= 0) return;

    bool bTemp = false;
    char auth[32];
    GetClientAuthId(client, AuthId_SteamID64, auth, sizeof(auth));
    if(g_hWhitelistTrie.GetValue(auth, bTemp))
    {
        return;
    }

    if(HasAccess(auth, g_sCvar_IgnoreAdmins))
    {
        return;
    }
    
    if(ownerauthid != authid)
    {
        char sReason[256];
        FormatEx(sReason, sizeof(sReason), "%T", "Message", client);

        if(g_iCvar_BanTime == -1)
        {
            KickClient(client, sReason);
            LogCustom("Kick %N [64 ID: %s, Owner Steam32 ID: %d] because of family sharing.", client, auth, ownerauthid);
        }
        else if(g_iCvar_BanTime == 0)
        {
            LogCustom("Banning %N [64 ID: %s, Owner Steam32 ID: %d] permanently because of family sharing.", client, auth, ownerauthid, g_iCvar_BanTime);
            
            //有使用sourceban++會記錄 (有名子顯示)
            //使用sm_ban 會立即踢人
            ServerCommand("sm_ban #%i %d \"%s\"", GetClientUserId(client), g_iCvar_BanTime, sReason);
        }
        else if(g_iCvar_BanTime > 0)
        {
            LogCustom("Banning %N [64 ID: %s, Owner Steam32 ID: %d] for %d minutes because of family sharing.", client, auth, ownerauthid, g_iCvar_BanTime);
            ServerCommand("sm_ban #%i %d \"%s\"", GetClientUserId(client), g_iCvar_BanTime, sReason);
        }
    }

    /*
    //Now using SteamWorks:
    EUserHasLicenseForAppResult result = SteamWorks_HasLicenseForApp(client, g_hCvar_AppId.IntValue);

    //Debug text: PrintToServer("Client %N License Value: %i", client, view_as<int>(result));

    //No License, kick em:
    if(result > k_EUserHasLicenseResultHasLicense)
    {
        char banMessage[PLATFORM_MAX_PATH]; g_hCvar_BanMessage.GetString(banMessage, sizeof(banMessage));
        KickClient(client, banMessage);
    }
    */
}

void LogCustom(const char[] format, any ...)
{
	char buffer[512];
	VFormat(buffer, sizeof(buffer), format, 2);

	char sPath[PLATFORM_MAX_PATH], sTime[32];
	BuildPath(Path_SM, sPath, sizeof(sPath), "logs/familyshare_manager.log");
	File file = OpenFile(sPath, "a+");
	FormatTime(sTime, sizeof(sTime), "%d-%b-%Y - %H:%M:%S");
	file.WriteLine("%s: %s", sTime, buffer);
	FlushFile(file);
	delete file;
}

bool HasAccess(char[] steamid, char[] sAcclvl)
{
    // no permissions set
    if (strlen(sAcclvl) == 0)
        return true;

    else if (StrEqual(sAcclvl, "-1"))
        return false;

    // check permissions
    AdminId id = FindAdminByIdentity(AUTHMETHOD_STEAM, steamid);
    if(id == INVALID_ADMIN_ID) return false;

    int flag = id.GetFlags(Access_Real);
    if ( flag & ReadFlagString(sAcclvl))
    {
        return true;
    }

    return false;
}
