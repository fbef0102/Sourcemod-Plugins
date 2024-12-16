#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION "1.0-2024/12/17"
#define DEBUG 0

public Plugin myinfo =
{
	name = "[Any] God Cvar",
	version = PLUGIN_VERSION,
	description = "Create a convar, so all players don't take damage",
	author = "HarryPotter",
	url = "https://steamcommunity.com/profiles/76561198026784913/"
}

bool bLate;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    bLate = late;
    return APLRes_Success;
}

ConVar g_hCvarGod;
bool g_bCvarGod;

public void OnPluginStart()
{
    g_hCvarGod = CreateConVar( "smd_god",        "0",   "All alive players don't take any damage", FCVAR_SERVER_CAN_EXECUTE | FCVAR_CHEAT | FCVAR_NOTIFY, true, 0.0, true, 1.0);

    GetCvars();
    g_hCvarGod.AddChangeHook(ConVarChanged_Cvars);

    if(bLate)
    {
        LateLoad();
    }
}

void LateLoad()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        OnClientPutInServer(client);
    }
}

//-------------------------------Cvars-------------------------------

void ConVarChanged_Cvars(ConVar hCvar, const char[] sOldVal, const char[] sNewVal)
{
	GetCvars();
}

void GetCvars()
{
    g_bCvarGod = g_hCvarGod.BoolValue;
}

//-------------------------------Sourcemod API Forward-------------------------------

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

//-------------------------------SDKHOOKS-------------------------------

Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damageType)
{
    if (!g_bCvarGod) return Plugin_Continue;
    if (!IsPlayerAlive(victim)) return Plugin_Continue;

    return Plugin_Handled;
}
