#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
#include <sourcemod>
#define PLUGIN_VERSION "1.0h-2025/11/21"

public Plugin myinfo = 
{
	name		= "[Any] Server Loader",
	author		= "HarryPotter",
	description	= "executes cfg file on server startup",
	version		= PLUGIN_VERSION,
	url 		= "https://steamcommunity.com/profiles/76561198026784913/"
}

ConVar sv_hibernate_when_empty;
ConVar cvarLoaderCfg;
int serverLoaderCounter = 0;

public void OnPluginStart()
{	
	cvarLoaderCfg = CreateConVar("server_loader", "server_loader.cfg", "Config that gets executed on server start. (Empty=Disable)");
	sv_hibernate_when_empty = FindConVar("sv_hibernate_when_empty");
	
	if(sv_hibernate_when_empty != null)
		sv_hibernate_when_empty.SetInt(false);
	
	CreateTimer(5.0, execConfig);
}

Action execConfig(Handle timer)
{
	if (serverLoaderCounter < 1)
	{
		static char loaderCfgString[256];
		cvarLoaderCfg.GetString(loaderCfgString, sizeof loaderCfgString);
		if (strlen(loaderCfgString) > 0)
		{
			ServerCommand("exec %s", loaderCfgString);
			//LogMessage("executed %s", loaderCfgString);
			serverLoaderCounter++;
		}
		else
		{
			LogError("No config or invalid config specified, no configs were loaded.");
			serverLoaderCounter++;
		}
	}

	return Plugin_Continue;
}

