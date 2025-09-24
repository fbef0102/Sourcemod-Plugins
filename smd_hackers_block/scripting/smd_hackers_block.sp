/**
 * SourceMod is licensed under the GNU General Public License, version 3.  
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <basecomm>

#define PLUGIN_VERSION			"1.4-2025/9/23"
#define PLUGIN_NAME			    "smd_hackers_block"
#define DEBUG 0

public Plugin myinfo =
{
	name = "[Any] Hackers Block",
	author = "xxx",
	description = "Block hackers using some exploit to crash server",
	version = PLUGIN_VERSION,
	url = "zzzzzzz"
};

bool g_bGameHas_SpecTeam;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion test = GetEngineVersion();

    if( test == Engine_Left4Dead
        || test == Engine_Left4Dead2
        || test == Engine_CSS
        || test == Engine_TF2 )
    {
        g_bGameHas_SpecTeam = true;
    }
    else
    {
        g_bGameHas_SpecTeam = false;
    }

    return APLRes_Success;
}

#define CVAR_FLAGS                    FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION     FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY

#define DATA_FILE		        "data/" ... PLUGIN_NAME ... ".cfg"
#define LOG_FILE		        "logs/" ... PLUGIN_NAME ... ".log"

ConVar g_hCvarEnable, g_hCvarTime, g_hCvarKick, g_hCvarSpec;
bool g_bCvarEnable, g_bCvarSpec;
int g_iCvarKick;
float g_fCvarTime;

char 
    sg_log[256];

int 
    g_iHackersDetect[MAXPLAYERS+1];

bool 
    g_bSteamIDNotValid[MAXPLAYERS+1];

Handle 
    g_hDetectTimer[MAXPLAYERS+1];

StringMap
    g_smBlockCmdList;

public void OnPluginStart()
{
    g_hCvarEnable 		= CreateConVar( PLUGIN_NAME ... "_enable",        "1",   "0=Plugin off, 1=Plugin on.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvarTime 		= CreateConVar( PLUGIN_NAME ... "_time",          "10.0","Time in seconds to check if players has steam id authorized after join server", CVAR_FLAGS, true, 0.0);
    g_hCvarKick         = CreateConVar( PLUGIN_NAME ... "_kick",          "1",   "1=Kick the player if no steam id authorized, 0=Log only", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvarSpec         = CreateConVar( PLUGIN_NAME ... "_spec",          "1",   "If 1, Force to spec/Block chat/Block voice/Block commands while no steam id available", CVAR_FLAGS, true, 0.0, true, 1.0);
    CreateConVar(                       PLUGIN_NAME ... "_version",       PLUGIN_VERSION, PLUGIN_NAME ... " Plugin Version", CVAR_FLAGS_PLUGIN_VERSION);
    AutoExecConfig(true,                PLUGIN_NAME);

    GetCvars();
    g_hCvarEnable.AddChangeHook(ConVarChanged_Cvars);
    g_hCvarTime.AddChangeHook(ConVarChanged_Cvars);
    g_hCvarKick.AddChangeHook(ConVarChanged_Cvars);
    g_hCvarSpec.AddChangeHook(ConVarChanged_Cvars);

    ParseCRASHCMDList();

    if(g_bGameHas_SpecTeam) HookEvent("player_team",            Event_PlayerTeam);

    BuildPath(Path_SM, sg_log, sizeof(sg_log), "%s", LOG_FILE);
}

// Cvars-------------------------------

void ConVarChanged_Cvars(ConVar hCvar, const char[] sOldVal, const char[] sNewVal)
{
	GetCvars();
}

void GetCvars()
{
    g_bCvarEnable = g_hCvarEnable.BoolValue;
    g_fCvarTime = g_hCvarTime.FloatValue;
    g_iCvarKick = g_hCvarKick.IntValue;
    g_bCvarSpec = g_hCvarSpec.BoolValue;
}

// Sourcemod API Forward-------------------------------

bool g_bServerLoaded = false,
    g_bServerFirstMap = true;
public void OnConfigsExecuted()
{
    if(g_bServerFirstMap)
    {
        g_bServerFirstMap = false;
        CreateTimer(30.0, Timer_ServerLoaded);
    }
}

public void OnClientConnected(int client) 
{
    if(IsFakeClient(client)) return;

    g_iHackersDetect[client] = 0;
    g_bSteamIDNotValid[client] = false;
}

public void OnClientPutInServer(int client) 
{
    if(!g_bCvarEnable) return;
    if(IsFakeClient(client)) return;

    char steamID[32];
    if (!GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID))) 
    {
        if(g_bCvarSpec)
        {
            g_bSteamIDNotValid[client] = true;
            BaseComm_SetClientMute(client, true);
        }

        delete g_hDetectTimer[client];
        g_hDetectTimer[client] = CreateTimer(g_fCvarTime, CheckSteamID, client);
    }
    else
    {
        g_bSteamIDNotValid[client] = false;
    }
}

public void OnClientAuthorized(int client)
{
    if(IsFakeClient(client)) return;
    
    delete g_hDetectTimer[client];
    g_bSteamIDNotValid[client] = false;

    if(g_bCvarSpec && IsClientInGame(client) && BaseComm_IsClientMuted(client)) BaseComm_SetClientMute(client, false);
}

public void OnClientDisconnect(int client)
{
    delete g_hDetectTimer[client];
}

// 不會檢測到客戶端能執行的指令
// 遊戲控制台輸入指令
public Action OnClientCommand(int client, int args) 
{
    if(!g_bCvarEnable || !g_bCvarSpec)
        return Plugin_Continue;

    if(client <= 0 || client > MaxClients || IsFakeClient(client))
        return Plugin_Continue;

    if(g_bSteamIDNotValid[client])
        return Plugin_Handled;

    return Plugin_Continue;
}

// 打字聊天
public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
    if(!g_bCvarEnable || !g_bCvarSpec)
        return Plugin_Continue;

    if(client <= 0 || client > MaxClients || IsFakeClient(client))
        return Plugin_Continue;

    if(g_bSteamIDNotValid[client])
        return Plugin_Stop;

    return Plugin_Continue;
}

// Data------------

void ParseCRASHCMDList()
{
    delete g_smBlockCmdList;
    g_smBlockCmdList = new StringMap();

    char sFile[256];
    BuildPath(Path_SM, sFile, sizeof(sFile), "%s", DATA_FILE);

    File hFile = OpenFile(sFile, "r");
    if(hFile == null)
    {
        LogError("%s not found", sFile);
        return;
    }

    static char sBuffer[256];
    while(!hFile.EndOfFile() && hFile.ReadLine(sBuffer, sizeof(sBuffer)))
    {
        if(strncmp(sBuffer, "//", 2, false) == 0)
        {
            continue;
        }

        TrimString(sBuffer);
        StripQuotes(sBuffer);

        if(strlen(sBuffer) <= 0) continue;

        g_smBlockCmdList.SetValue(sBuffer, true);

        RegConsoleCmd(sBuffer, CMD_CRASH);
    }

    delete hFile;
}

// Command-------------------------------

Action CMD_CRASH(int client, int args)
{
    if(!g_bCvarEnable) return Plugin_Continue;

    if(client > 0 && !IsFakeClient(client))
    {
        g_iHackersDetect[client]++;
        if(g_iHackersDetect[client] >= 5)
        {
            static char steamID[32];
            GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID)); 

            static char ip[32];
            GetClientIP(client, ip, sizeof(ip));

            static char sCmdName[12];
            GetCmdArg(0, sCmdName, sizeof(sCmdName));
            
            LogToFileEx(sg_log, "Kick %N <%s>, IP: %s, Reason: %s command abuse", client, steamID, ip, sCmdName);
            
            KickClient(client, "Nice try, hacker!");
        }
    }

    return Plugin_Handled;
}

// Event------------

void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast) 
{
    if(!g_bCvarEnable || !g_bCvarSpec) return;

    int userid = event.GetInt("userid");
    CreateTimer(1.0, PlayerChangeTeamCheck, userid);//延遲一秒檢查
}

// Timer & Frame-------------------------------

Action PlayerChangeTeamCheck(Handle timer,int userid)
{
    int client = GetClientOfUserId(userid);
    if (client && IsClientInGame(client) && GetClientTeam(client) > 1)
    {
        if(g_bSteamIDNotValid[client])
        {
            ChangeClientTeam(client, 1);
            PrintToChat(client, "Unable to play games while steam id not authorized!!");
        }
    }

    return Plugin_Continue;
}

Action Timer_ServerLoaded(Handle timer)
{
    g_bServerLoaded = true;

    return Plugin_Continue;
}

//駭客阻止Steam ID驗證導致ban失效
Action CheckSteamID(Handle timer, int client) 
{
    g_hDetectTimer[client] = null;

    if (!g_bCvarEnable || !IsClientInGame(client) || IsFakeClient(client)) 
    {
        return Plugin_Continue;
    }

    if(!g_bServerLoaded)
    {
        g_hDetectTimer[client] = CreateTimer(g_fCvarTime, CheckSteamID, client);
        return Plugin_Continue;
    }

    char steamID[32];
    if (!GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID))) 
    {
        char ip[32];
        GetClientIP(client, ip, sizeof(ip));

        if(g_iCvarKick == 1)
        {
            LogToFileEx(sg_log, "Kick %N <STEAM_ID_PENDING>, IP: %s, Reason: no steam id available", client, ip);
            KickClient(client, "AuthId not valid");
        }
        else
        {
            LogToFileEx(sg_log, "Warning! Careful %N <STEAM_ID_PENDING>, IP: %s, Reason: no steam id available", client, ip);
        }
    }
    else
    {
        g_bSteamIDNotValid[client] = false;
        if(g_bCvarSpec && BaseComm_IsClientMuted(client)) BaseComm_SetClientMute(client, false);
    }

    return Plugin_Continue;
}