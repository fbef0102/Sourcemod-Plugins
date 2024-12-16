#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法

#include <sourcemod>
#include <sdktools>
#include <geoip>
#include <string>
#include <cstrike>
#include <basecomm>

#define PLUGIN_VERSION			"1.2-2024/4/7"
#define PLUGIN_NAME			    "css_savechat_command"
#define DEBUG 0

public Plugin myinfo = 
{
	name = "[CSS] SaveChat/SaveCommand",
	author = "Harry Potter",
	description = "Records player chat messages and commands to a file",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/profiles/76561198026784913/"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion test = GetEngineVersion();

    if( test != Engine_CSS )
    {
        strcopy(error, err_max, "Plugin only supports CSS.");
        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}

#define CVAR_FLAGS                    FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION     FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY

ConVar hostport;
char sHostport[10];

char chatFile[128];
Handle fileHandle       = null;
ConVar g_hCvarEnable, g_hCvarConsole;
bool g_bCvarEnable, g_bCvarConsole;

StringMap
	g_smIgnoreList;

public void OnPluginStart()
{
	hostport = FindConVar("hostport");

	g_hCvarEnable = 	CreateConVar( PLUGIN_NAME ... "_enable", 			"1", "0=Plugin off, 1=Plugin on.", CVAR_FLAGS, true, 0.0, true, 1.0); 
	g_hCvarConsole = 	CreateConVar( PLUGIN_NAME ... "_cosole_command", 	"1", "If 1, Record and save console commands.", CVAR_FLAGS, true, 0.0, true, 1.0); 
	CreateConVar(                     PLUGIN_NAME ... "_version",       	PLUGIN_VERSION, PLUGIN_NAME ... " Plugin Version", CVAR_FLAGS_PLUGIN_VERSION);
	AutoExecConfig(true, PLUGIN_NAME);
	
	GetCvars();
	hostport.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarEnable.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarConsole.AddChangeHook(ConVarChanged_Cvars);

	HookEvent("player_disconnect", 	event_PlayerDisconnect);

	g_smIgnoreList = new StringMap();
	g_smIgnoreList.SetValue("spec_prev", true);
	g_smIgnoreList.SetValue("spec_next", true);
	g_smIgnoreList.SetValue("spec_mode", true);
	g_smIgnoreList.SetValue("buyammo1", true);
	g_smIgnoreList.SetValue("buyammo2", true);
	g_smIgnoreList.SetValue("commandmenu", true);
	g_smIgnoreList.SetValue("vmodenable", true); // join server check
	g_smIgnoreList.SetValue("vban", true); // join server check
	g_smIgnoreList.SetValue("joingame", true); // joingame
	g_smIgnoreList.SetValue("jointeam", true); // jointeam
	g_smIgnoreList.SetValue("joinclass", true); // select character
	g_smIgnoreList.SetValue("menuselect", true); //menuselect 1~9
	g_smIgnoreList.SetValue("demo", true); // character vocalize
	g_smIgnoreList.SetValue("achievement_earned", true); // achievement_earned x x
	g_smIgnoreList.SetValue("drop", true); // drop weapon
	g_smIgnoreList.SetValue("buy", true); // buy weapon
	g_smIgnoreList.SetValue("spec_next", true); // spec_next
	g_smIgnoreList.SetValue("spec_prev", true); // spec_prev
	g_smIgnoreList.SetValue("nightvision", true); // nightvision

}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bCvarEnable = g_hCvarEnable.BoolValue;
	g_bCvarConsole = g_hCvarConsole.BoolValue;
	hostport.GetString(sHostport, sizeof(sHostport));
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if(g_bCvarEnable == false)
		return Plugin_Continue;

	if(client < 0 || client > MaxClients)
		return Plugin_Continue;

	if (client > 0 && IsClientInGame(client) && BaseComm_IsClientGagged(client) == true) //this client has been gagged
		return Plugin_Continue;	

	if (strcmp(command, "say_team") == 0)
	{
		LogChat2(client, sArgs, true);
	}
	else
	{
		LogChat2(client, sArgs, false);
	}

	return Plugin_Continue;
}

// 不會檢測到客戶端能執行的指令
public Action OnClientCommand(int client, int args) 
{
	if(g_bCvarEnable == false || g_bCvarConsole == false)
		return Plugin_Continue;

	if(client < 0 || client > MaxClients)
		return Plugin_Continue;

	LogCommand(client, args);
	return Plugin_Continue;
}

public void OnMapStart(){
	if(g_bCvarEnable == false)
		return;

	char map[128];
	char msg[1024];
	char date[21];
	char time[21];
	char logFile[100];

	GetCurrentMap(map, sizeof(map));

	/* The date may have rolled over, so update the logfile name here */
	FormatTime(date, sizeof(date), "%Y_%m_%d", -1);
	Format(logFile, sizeof(logFile), "/logs/chat/server_%s_chat_%s.log", sHostport, date);
	BuildPath(Path_SM, chatFile, PLATFORM_MAX_PATH, logFile);

	FormatTime(time, sizeof(time), "%d/%m/%Y %H:%M:%S", -1);
	Format(msg, sizeof(msg), "[%s] --- Map: %s ---", time, map);

	SaveMessage("--=================================================================--");
	SaveMessage(msg);
	SaveMessage("--=================================================================--");
}


public void OnClientPostAdminCheck(int client)
{
	if(g_bCvarEnable == false)
		return;

	if(IsFakeClient(client)) 
		return;

	static char msg[2048];
	static char time[21];
	static char country[3];
	static char steamID[128];
	static char playerIP[50];
	
	GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
	
	if(GetClientIP(client, playerIP, sizeof(playerIP), true) == false) {
		//country   = "  "
	} else {
		if(GeoipCode2(playerIP, country) == false) {
			//country = "  ";
		}
	}
	
	FormatTime(time, sizeof(time), "%H:%M:%S", -1);
	FormatEx(msg, sizeof(msg), "[%s] (%-20s | %-15s) %-25N has joined.",
		time,
		steamID,
		playerIP,
		client);

	SaveMessage(msg);
}

void event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast) 
{
	if(g_bCvarEnable == false)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));

	static char msg[2048];
	static char time[21];
	//static char country[3];
	static char steamID[64];
	static char playerIP[50];
	static char reason[128];
	event.GetString("reason", reason, sizeof(reason));
	
	if(client == 0 && strcmp(reason, "Connection closing", false) == 0)
	{
		static char playerName[128];
		event.GetString("name", playerName, sizeof(playerName));

		static char networkid[32];
		event.GetString("networkid", networkid, sizeof(networkid));

		FormatTime(time, sizeof(time), "%H:%M:%S", -1);
		FormatEx(msg, sizeof(msg), "[%s] (%-20s | %-15s) %-25s has left (%s).",
			time,
			networkid,
			"Unknown",
			playerName,
			reason);

		SaveMessage(msg);
		return;
	}
	
	if( client && !IsFakeClient(client) && !dontBroadcast )
	{
		GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
		
		if(GetClientIP(client, playerIP, sizeof(playerIP), true) == false) {
			//country   = "  "
		} else {
			//if(GeoipCode2(playerIP, country) == false) {
			//	//country = "  ";
			//}
		}
		
		FormatTime(time, sizeof(time), "%H:%M:%S", -1);
		FormatEx(msg, sizeof(msg), "[%s] (%-20s | %-15s) %-25N has left (%s).",
			time,
			steamID,
			playerIP,
			client,
			reason);

		SaveMessage(msg);
	}
}

void LogChat2(int client, const char[] sArgs, bool teamchat)
{
	static char msg[2048];
	static char time[21];
	static char country[3];
	static char playerIP[50];
	static char teamName[20];
	static char steamID[128];
	
	if (client == 0 || !IsClientInGame(client)) {
		country[0] = '\0';
		teamName[0] = '\0';
		playerIP[0] = '\0';
		steamID[0] = '\0';
	} else {
		if(GetClientIP(client, playerIP, sizeof(playerIP), true) == false) {
			//country   = "  ";
		} else {
			if(GeoipCode2(playerIP, country) == false) {
				//country = "  ";
			}
		}
		my_GetTeamName(GetClientTeam(client), teamName, sizeof(teamName));
		GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
	}
	FormatTime(time, sizeof(time), "%H:%M:%S", -1);

	FormatEx(msg, sizeof(msg), "[%s] (%-20s | %-15s) [%s] %-25N : %s%s",
		time,
		steamID,
		playerIP,
		teamName,
		client,
		teamchat == true ? "(TEAM) " : "",
		sArgs);

	SaveMessage(msg);
}

stock void LogCommand(int client, int args)
{
	static char cmd[64];
	static char text[1024];

	GetCmdArg(0, cmd, sizeof(cmd));
	StringToLowerCase(cmd);
	bool bTemp;
	if( g_smIgnoreList.GetValue(cmd, bTemp) == true )
	{
		return;
	}

	GetCmdArgString(text, sizeof(text));
	StripQuotes(text);

	static char country[3];
	static char playerIP[50];
	static char teamName[20];
	static char msg[2048];
	static char time[21];
	static char steamID[128];
	
	if (client == 0 || !IsClientInGame(client)) {
		country[0] = '\0';
		teamName[0] = '\0';
		playerIP[0] = '\0';
		steamID[0] = '\0';
	} else {
		/* Get 2 digit country code for current player */
		if(GetClientIP(client, playerIP, sizeof(playerIP), true) == false) {
			//country   = "  ";
		} else {
			if(GeoipCode2(playerIP, country) == false) {
				//country = "  ";
			}
		}
		my_GetTeamName(GetClientTeam(client), teamName, sizeof(teamName));
		GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
	}
	FormatTime(time, sizeof(time), "%H:%M:%S", -1);

	FormatEx(msg, sizeof(msg), "[%s] (%-20s | %-15s) [%s] %-25N : (CMD) %s %s",
		time,
		steamID,
		playerIP,
		teamName,
		client,
		cmd,
		text);

	SaveMessage(msg);
}

void SaveMessage(const char[] message)
{
	fileHandle = OpenFile(chatFile, "a");  /* Append */
	if(fileHandle == null)
	{
		CreateDirectory("/addons/sourcemod/logs/chat", 777);
		fileHandle = OpenFile(chatFile, "a"); //open again
		if(fileHandle == null)
		{
			LogError("Can not create chat file: %s", chatFile);
			return;
		}
	}
	WriteFileLine(fileHandle, message);
	delete fileHandle;
}

void my_GetTeamName(int team, char[] sTeamName, int size)
{
	switch(team)
	{
		case CS_TEAM_SPECTATOR:
		{
			FormatEx(sTeamName, size, "Spe");
		}
		case CS_TEAM_T:
		{
			FormatEx(sTeamName, size, "T");
		}
		case CS_TEAM_CT:
		{
			FormatEx(sTeamName, size, "CT");
		}
		default:
		{
			FormatEx(sTeamName, size, "None");
		}
	}
}

void StringToLowerCase(char[] input)
{
    for (int i = 0; i < strlen(input); i++)
    {
        input[i] = CharToLower(input[i]);
    }
}