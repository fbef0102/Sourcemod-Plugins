#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
#include <sourcemod>
#define PLUGIN_VERSION "1.2h-2026/9/30"

public Plugin myinfo = 
{
	name		= "[Any] Server Loader",
	author		= "HarryPotter",
	description	= "executes cfg file on server startup",
	version		= PLUGIN_VERSION,
	url 		= "https://steamcommunity.com/profiles/76561198026784913/"
}

bool g_bGameL4D;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if(test == Engine_Left4Dead || test == Engine_Left4Dead2)
	{
		g_bGameL4D = true;
	}

	return APLRes_Success;
}

ConVar sv_hibernate_when_empty;
ConVar cvarLoaderCfg, cvarLoaderDone;
bool g_ServerLoadedConfig = false;
bool g_bForceSserverWakeUp;

public void OnPluginStart()
{	
	cvarLoaderCfg 	= CreateConVar("server_loader", 		"server_loader.cfg", 	"Config that gets executed on server start. (Empty=Disable)");
	cvarLoaderDone 	= CreateConVar("server_loader_done", 	"0", 					"0=Try to execute startup config, 1=Startup config already executed, do not execute again on plugin reload. (Set 0 to allow it again)", FCVAR_DONTRECORD);
	if(g_bGameL4D)
	{
		g_bForceSserverWakeUp = true;
		sv_hibernate_when_empty = FindConVar("sv_hibernate_when_empty");
		sv_hibernate_when_empty.AddChangeHook(ConVarChanged_Hibernate);
		sv_hibernate_when_empty.SetBool(false);
	}
	
	CreateTimer(5.0, execConfig);
}

void ConVarChanged_Hibernate(ConVar hCvar, const char[] sOldVal, const char[] sNewVal)
{
	if(g_bForceSserverWakeUp) sv_hibernate_when_empty.SetBool(false);
}

Action execConfig(Handle timer)
{
	g_bForceSserverWakeUp = false;

	if (g_ServerLoadedConfig == false && !cvarLoaderDone.BoolValue)
	{
		static char loaderCfgString[256];
		cvarLoaderCfg.GetString(loaderCfgString, sizeof loaderCfgString);
		if (strlen(loaderCfgString) > 0)
		{
			ServerCommand("exec %s", loaderCfgString);
			//LogMessage("executed %s", loaderCfgString);
			g_ServerLoadedConfig = true;

			cvarLoaderDone.SetBool(true);
		}
		else
		{
			//LogError("server_loader cvar \"server_loader\" not set.");
			g_ServerLoadedConfig = true;

			cvarLoaderDone.SetBool(true);
		}
	}

	return Plugin_Continue;
}

