#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION			"1.0"
#define PLUGIN_NAME			    "smd_restartmap_command"
#define DEBUG 0

public Plugin myinfo =
{
	name = "[Any] Restart Map Command",
	author = "HarryPotter",
	description = "Admin say !restartmap to restart current map",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/profiles/76561198026784913/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    return APLRes_Success;
}

#define CVAR_FLAGS                    FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION     FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY

ConVar g_hCvarEnable, g_hCvarAnnounceType, g_hCvarDelay, g_hCommandAccess,
	g_hSoundFile;
bool g_bCvarEnable;
int g_iCvarAnnounceType, g_iCvarDelay;
char g_sCommandAcclvl[16], g_sCvarSoundFile[PLATFORM_MAX_PATH];

bool g_bMapStart;
int g_iMapRestartDelay;
Handle MapCountdownTimer;

public void OnPluginStart()
{
	g_hCvarEnable 				= CreateConVar( PLUGIN_NAME ... "_enable",      	"1",  					"0=Plugin off, 1=Plugin on.", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvarAnnounceType 		= CreateConVar( PLUGIN_NAME ... "_announce_type", 	"1", 					"Changes how message displays. (0: Disable, 1:In chat, 2: In Hint Box, 3: In center text)", CVAR_FLAGS, true, 0.0, true, 3.0);
	g_hCvarDelay 				= CreateConVar(	PLUGIN_NAME ... "_delay",       	"5", 					"Delay to restart map.", CVAR_FLAGS, true, 0.0);
	g_hCommandAccess 			= CreateConVar(	PLUGIN_NAME ... "_access_flag", 	"z",  					"Players with these flags have access to use command to restart map. (Empty = Everyone, -1: Nobody)", CVAR_FLAGS);
	g_hSoundFile 				= CreateConVar(	PLUGIN_NAME ... "_soundfile",   	"buttons/blip1.wav", 	"Count down sound file (relative to to sound/, empty=disable)", CVAR_FLAGS);
	CreateConVar(                       PLUGIN_NAME ... "_version",      	PLUGIN_VERSION, PLUGIN_NAME ... " Plugin Version", CVAR_FLAGS_PLUGIN_VERSION);
	AutoExecConfig(true, 				PLUGIN_NAME);

	GetCvars();
	g_hCvarEnable.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarAnnounceType.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDelay.AddChangeHook(ConVarChanged_Cvars);
	g_hCommandAccess.AddChangeHook(ConVarChanged_Cvars);
	g_hSoundFile.AddChangeHook(ConVarChanged_Cvars_Sound);

	RegConsoleCmd("sm_restartmap", CommandRestartMap, "sm_restartmap - changelevels to the current map");
	RegConsoleCmd("sm_rs", CommandRestartMap, "sm_restartmap - changelevels to the current map");
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

public void ConVarChanged_Cvars_Sound(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();

	if (strlen(g_sCvarSoundFile) > 0 && g_bMapStart)
	{
		PrecacheSound(g_sCvarSoundFile);
	}
}

void GetCvars()
{
	g_bCvarEnable = g_hCvarEnable.BoolValue;
	g_iCvarAnnounceType = g_hCvarAnnounceType.IntValue;
	g_iCvarDelay = g_hCvarDelay.IntValue;
	g_hCommandAccess.GetString(g_sCommandAcclvl,sizeof(g_sCommandAcclvl));
	g_hSoundFile.GetString(g_sCvarSoundFile, sizeof(g_sCvarSoundFile));
}

public void OnConfigsExecuted()
{
	GetCvars();
}

char g_sCurrentMap[256];
public void OnMapStart()
{
	GetCurrentMap(g_sCurrentMap, 256);

	g_bMapStart = true;
	MapCountdownTimer = null;

	if (strlen(g_sCvarSoundFile) > 0) PrecacheSound(g_sCvarSoundFile, true);
}

public void OnMapEnd()
{
   g_bMapStart = false;
}

//-------------------------------Command-------------------------------

public Action CommandRestartMap(int client, int args)
{	
	if(g_bCvarEnable == false)
	{
		return Plugin_Handled;
	}

	if(MapCountdownTimer != null)
	{
		return Plugin_Handled;
	}

	if(client > 0 && HasAccess(client, g_sCommandAcclvl) == false)
	{
		ReplyToCommand(client, "[TS] You don't have access to restart map");
		return Plugin_Handled;
	}

	RestartMapDelayed();

	return Plugin_Handled;
}

void RestartMapDelayed()
{
	g_iMapRestartDelay = g_iCvarDelay;
	switch(g_iCvarAnnounceType)
	{
		case 0: {/*nothing*/}
		case 1: {
			PrintToChatAll("\x01Get Ready! Map restart in \x04%d", g_iMapRestartDelay);
		}
		case 2: {
			PrintHintTextToAll("Get Ready! Map restart in %d", g_iMapRestartDelay);
		}
		case 3: {
			PrintCenterTextAll("Get Ready! Map restart in %d", g_iMapRestartDelay);
		}
	}

	if (strlen(g_sCvarSoundFile) > 0) EmitSoundToAll(g_sCvarSoundFile, _, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
	
	g_iMapRestartDelay--;
	delete MapCountdownTimer;
	MapCountdownTimer = CreateTimer(1.0, Timer_RestartMap, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

//-------------------------------Timer & Frame-------------------------------

Action Timer_RestartMap(Handle timer)
{
	if (g_iMapRestartDelay == 0)
	{
		RestartMapNow();

		MapCountdownTimer = null;
		return Plugin_Stop;
	}
	
	switch(g_iCvarAnnounceType)
	{
		case 0: {/*nothing*/}
		case 1: {
			PrintToChatAll("\x01Get Ready! Map restart in \x04%d", g_iMapRestartDelay);
		}
		case 2: {
			PrintHintTextToAll("Get Ready! Map restart in %d", g_iMapRestartDelay);
		}
		case 3: {
			PrintCenterTextAll("Get Ready! Map restart in %d", g_iMapRestartDelay);
		}
	}

	g_iMapRestartDelay--;

	if (strlen(g_sCvarSoundFile) > 0) EmitSoundToAll(g_sCvarSoundFile, _, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);

	return Plugin_Continue;
}

//-------------------------------Function-------------------------------

void RestartMapNow() 
{
	ServerCommand("changelevel %s", g_sCurrentMap);
}

bool HasAccess(int client, char[] g_sAcclvl)
{
	// no permissions set
	if (strlen(g_sAcclvl) == 0)
		return true;

	else if (StrEqual(g_sAcclvl, "-1"))
		return false;

	// check permissions
	if ( GetUserFlagBits(client) & ReadFlagString(g_sAcclvl))
	{
		return true;
	}

	return false;
}