#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
#include <sourcemod>
#define PLUGIN_VERSION "1.3"

public Plugin myinfo = 
{
	name		= "[Any] Server Loader",
	author		= "HarryPotter",
	description	= "executes cfg file on server startup",
	version		= PLUGIN_VERSION,
	url 		= "https://steamcommunity.com/profiles/76561198026784913/"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();

	if( test == Engine_Left4Dead2 || test == Engine_Left4Dead)
	{
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

ConVar sv_hibernate_when_empty;
ConVar cvarLoaderCfg;
int serverLoaderCounter = 0;

public void OnPluginStart()
{	
	cvarLoaderCfg = CreateConVar("server_loader", "server_startup.cfg", "Config that gets executed on server start. (Empty=Disable)");
	sv_hibernate_when_empty = FindConVar("sv_hibernate_when_empty");
	
	if(sv_hibernate_when_empty != null)
		sv_hibernate_when_empty.SetInt(false);
	
	CreateTimer(5.0, execConfig, TIMER_FLAG_NO_MAPCHANGE);
}

Action execConfig(Handle timer)
{
	if (serverLoaderCounter < 1)
	{
		static char loaderCfgString[128];
		GetConVarString(cvarLoaderCfg, loaderCfgString, 128);
		if (strlen(loaderCfgString) > 4)
		{
			ServerCommand("exec %s", loaderCfgString);
			LogMessage("executed %s", loaderCfgString);
			serverLoaderCounter++;
		}
		else
		{
			LogMessage("no config or invalid config specified, no configs were loaded.");
			serverLoaderCounter++;
		}
	}

	return Plugin_Continue;
}

