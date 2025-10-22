#define PLUGIN_VERSION		"1.0h-2025/10/11"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#tryinclude <left4dhooks>

#if !defined _l4dh_included
	native bool L4D_IsInFirstCheckpoint(int client);
	native bool L4D_IsInLastCheckpoint(int client);
#endif

public Plugin myinfo =
{
	name = "[ANY] Entity Limits Logger",
	author = "Dragokas, Harry",
	description = "Analyse and logs entity classes delta when the total number of entities on the map exceeds a pre-prefined maximum",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas"
}

bool g_bL4D;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();

	if( test == Engine_Left4Dead || test == Engine_Left4Dead2 )
	{
		g_bL4D = true;
	}

	MarkNativeAsOptional("L4D_IsInFirstCheckpoint");
	MarkNativeAsOptional("L4D_IsInLastCheckpoint");

	return APLRes_Success;
}

#define MODEL_ERROR 	"models/error.mdl"
#define CVAR_FLAGS		FCVAR_NOTIFY
#define DEBUG 			0

enum ENTITY_INFO_LEVEL
{
	ENTITY_INFO_NAME = 1,
	ENTITY_INFO_CLASS = 2,
	ENTITY_INFO_MODEL = 4,
	ENTITY_INFO_ORIGIN = 8,
	ENTITY_INFO_INDEX = 16,
	ENTITY_INFO_HAMMERID = 32,
	ENTITY_INFO_ALL = -1
}

ConVar g_hCVarUnsafeLeft;
ConVar g_hCVarDelay;
ConVar hostport;

File g_hLog;

char 
	sHostport[10],
	g_sLogPath[PLATFORM_MAX_PATH+1];

bool g_bCanLogged;

int g_iEntityLimit = 99999;
int g_iSnapTime;

StringMap g_hSnapClass;

public void OnPluginStart()
{
	hostport = FindConVar("hostport");

	CreateConVar("entity_limit_logger_version", PLUGIN_VERSION, "Plugin Version", CVAR_FLAGS | FCVAR_DONTRECORD);
	
	g_hCVarUnsafeLeft 	= CreateConVar("entity_limit_logger_unsafe_left", "100", "Plugin creates report when the number of free entities is less than this ConVar", CVAR_FLAGS );
	g_hCVarDelay 		= CreateConVar("entity_limit_logger_delay", "10.0", "Delay to be used after map start to create entities snapshot for calculating the entities delta when a leak happens", CVAR_FLAGS );
	
	AutoExecConfig(true, "entity_limit_logger");
	
	g_hCVarUnsafeLeft.AddChangeHook(ConVarChanged_Cvars);
	hostport.AddChangeHook(ConVarChanged_Cvars);
	
	GetCvars();
	
	g_hSnapClass = new StringMap();
	
	RegAdminCmd("sm_entlog",	CmdEntityLog, 	ADMFLAG_ROOT, "Creates entities report");
	RegAdminCmd("sm_logent",	CmdEntityLog, 	ADMFLAG_ROOT, "Creates entities report");
	RegAdminCmd("sm_entsnap",	CmdEntitySnap, 	ADMFLAG_ROOT, "Creates entities snapshot which is to be used for calculating the entities delta (when leak happens or sm_entlog used)");
	
	#if DEBUG
		RegAdminCmd("sm_entcrash", CmdCreateEntities, ADMFLAG_ROOT, "Creates 300 dummy entities in attempt to crash the server for test purposes");
	#endif
}

Action CmdEntityLog(int client, int args)
{
	LogAll(client);
	return Plugin_Handled;
}

Action CmdEntitySnap(int client, int args)
{
	MakeSnapshot();
	ReplyToCommand(client, "Entity snapshot is created.");
	return Plugin_Handled;
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iEntityLimit = GetMaxEntities() - g_hCVarUnsafeLeft.IntValue;
	hostport.GetString(sHostport, sizeof(sHostport));
}

#if DEBUG
Action CmdCreateEntities(int client, int args)
{
	const int COUNT = 300;
	int entity;
	float vOrigin[3];
	
	if( client && GetClientTeam(client) != 1 && IsPlayerAlive(client) )
	{
		GetClientAbsOrigin(client, vOrigin);
	}
	for( int i = 0; i < COUNT; i++ )
	{
		entity = CreateEntityByName("prop_dynamic_override"); // CDynamicProp
		if (entity != -1) {
			DispatchKeyValue(entity, "spawnflags", "0");
			DispatchKeyValue(entity, "solid", "0");
			DispatchKeyValue(entity, "disableshadows", "1");
			DispatchKeyValue(entity, "disablereceiveshadows", "1");
			DispatchKeyValue(entity, "model", MODEL_ERROR);
			TeleportEntity(entity, vOrigin, NULL_VECTOR, NULL_VECTOR);
			DispatchSpawn(entity);
			AcceptEntityInput(entity, "TurnOn");
			SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
			SetEntityRenderColor(entity, 0, 0, 0, 0);
		}
	}
	ReplyToCommand(client, "Created %i entities. Total: %i", COUNT, GetEntityCount());
	return Plugin_Handled;
}
#endif

public void OnMapStart()
{
	g_bCanLogged = true;
	CreateTimer(g_hCVarDelay.FloatValue, Timer_CreateSnapshot, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_CreateSnapshot(Handle timer)
{
	MakeSnapshot();

	return Plugin_Continue;
}

void MakeSnapshot()
{
	char data[300];
	int count;
	int ent = -1;

	g_iSnapTime = GetTime();
	
	delete g_hSnapClass;

	g_hSnapClass = new StringMap();
	
	while( -1 != (ent = FindEntityByClassname(ent, "*")))
	{
		if( IsValidEntity(ent) )
		{
			data = GetEntityInfoString(ent, ENTITY_INFO_INDEX | ENTITY_INFO_CLASS | ENTITY_INFO_NAME);
			
			GetEntityClassname(ent, data, sizeof(data));
			count = 0;
			g_hSnapClass.GetValue(data, count);
			++ count;
			g_hSnapClass.SetValue(data, count, true);
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if( g_bCanLogged && GetEntityCount() > g_iEntityLimit )
	{
		g_bCanLogged = false; // log every 360.0 second
		CreateTimer(360.0, Timer_LogAgain, TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(3.0, Timer_LogAll, _, TIMER_FLAG_NO_MAPCHANGE);
		
	}
}

Action Timer_LogAll(Handle timer)
{
	LogAll();

	return Plugin_Continue;
}

Action Timer_LogAgain(Handle Timer)
{
	g_bCanLogged = true;

	return Plugin_Continue;
}

void LogAll(int client = 0)
{
	char sTime[32], sMap[64];
	FormatTime(sTime, sizeof(sTime), "%F_%H-%M-%S", GetTime());
	BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), "logs/entity_limit_%s_%s.log", sHostport,sTime);
	GetCurrentMap(sMap, sizeof(sMap));
	
	LogTo("Logfile of 'Entity Limit Logger' v.%s\n", PLUGIN_VERSION);
	LogTo("----------------------------------------------");
	LogTo("Server Port:     %s", sHostport);
	LogTo("Map:             %s", sMap);
	FormatTime(sTime, sizeof(sTime), "%H h. %M m. %S s.", GetTime());
	LogTo("Current time:    %s", sTime);
	FormatTime(sTime, sizeof(sTime), "%H h. %M m. %S s.", g_iSnapTime);
	LogTo("Snapshot time:   %s", sTime);
	LogTo("Time passed:     %i min.", (GetTime() - g_iSnapTime) / 60);
	LogTo("----------------------------------------------");
	
	ReportDelta();
	ReportEntityTotal(client);
	ReportPrecacheInfo();
	ReportClientWeapon();
	
	LogTo("\nEnd of Report.");
	
	CloseLog();
	
	if( client )
		ReplyToCommand(client, "Entities log is saved to: %s", g_sLogPath);
}

void ReportDelta()
{
	LogTo("\nDELTA - {Class Count}\n" ...
		"*\n" ...
			"\tThis section describes the number of entity classes, which increased since the latest snapshot" ...
		"\n*\n");
	ReportDelta_ClassCount();
	
	//LogTo("\nDELTA - {Entity List}\n" ...
	//	"*\n" ...
	//		"\tThis section describes each separate entity, created since the latest snapshot" ...
	//	"\n*\n");
	//ReportDelta_Entities();
}

void ReportDelta_ClassCount()
{
	StringMap hSnapClassNew;
	StringMapSnapshot hEnum;
	char sClass[64];
	int count, count_old;
	
	hSnapClassNew = new StringMap();
	
	int ent = -1;
	while( -1 != (ent = FindEntityByClassname(ent, "*")))
	{
		if( IsValidEntity(ent) )
		{
			GetEntityClassname(ent, sClass, sizeof(sClass));
			count = 0;
			hSnapClassNew.GetValue(sClass, count);
			++ count;
			hSnapClassNew.SetValue(sClass, count, true);
		}
	}
	hEnum = hSnapClassNew.Snapshot();
	
	for( int i = 0; i < hEnum.Length; i++ )
	{
		hEnum.GetKey(i, sClass, sizeof(sClass));
		
		hSnapClassNew.GetValue(sClass, count);
		g_hSnapClass.GetValue(sClass, count_old);
		
		if( count > count_old )
		{
			LogTo("+%i\t%s", count - count_old, sClass);
		}
	}
	delete hEnum;
	delete hSnapClassNew;
}

void ReportEntityTotal(int client)
{
	LogTo("\n***********************" ...
			"     TOTAL NETWORKING ENTITIES    " ...
			"***********************\n");

	int count = 0;
	for (int ent = 1; ent < GetMaxEntities(); ent++)
	{
		if(!IsValidEntity(ent)) continue;

		LogTo(GetEntityInfoString(ent, ENTITY_INFO_ALL &~ ENTITY_INFO_INDEX, true));

		count++;
	}

	LogTo("Total Networking Entities: %d", count);
	LogTo("---------------------------------------------------------");

	PrintToServer("Total Networking Entities: %d", count);
	PrintToServer("---------------------------------------------------------");

	if(client > 0)
	{
		PrintToChat(client, "Total Networking Entities: %d", count);
		PrintToChat(client, "---------------------------------------------------------");
	}

	LogTo("\n***********************" ...
			"     TOTAL NON-NETWORKING ENTITIES    " ...
			"***********************\n");

	int entity = INVALID_ENT_REFERENCE;
	count = 0;
	while((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT_REFERENCE)
	{
		if (!IsValidEntity(entity))
			continue;

		int index = EntRefToEntIndex(entity);
		if (index <= GetMaxEntities())
			continue;

		LogTo(GetEntityInfoString(entity, ENTITY_INFO_ALL &~ ENTITY_INFO_INDEX, false));

		count++;
	}

	LogTo("Total non-networked Entities: %d", count);
	LogTo("---------------------------------------------------------");
	
	PrintToServer("Total non-networked Entities: %d", count);
	PrintToServer("---------------------------------------------------------");

	if(client > 0)
	{
		PrintToChat(client, "Total non-networked Entities: %d", count);
		PrintToChat(client, "---------------------------------------------------------");
	}
}

char[] GetEntityInfoString(int entity, ENTITY_INFO_LEVEL info_level, bool bIsNetwork = true)
{
	static char sClass[64], sName[128], sIndex[8];
	static char sModel[PLATFORM_MAX_PATH];
	static float pos[3];
	
	char result[300];
	int iHammerID;
	
	pos[0] = 0.0;
	pos[1] = 0.0;
	pos[2] = 0.0;
	sModel[0] = 0;
	sName[0] = 0;
	sClass[0] = 0;
	sIndex[0] = 0;
	
	if( info_level & ENTITY_INFO_ORIGIN )
	{
		if( HasEntProp(entity, Prop_Data, "m_vecAbsOrigin"))
		{
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
		}
	}
	if( info_level & ENTITY_INFO_MODEL )
	{
		if( HasEntProp(entity, Prop_Data, "m_ModelName") )
		{
			GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
		}
	}
	if( info_level & ENTITY_INFO_NAME )
	{
		if( HasEntProp(entity, Prop_Data, "m_iName") )
		{
			GetEntPropString(entity, Prop_Data, "m_iName", sName, sizeof(sName));
		}
	}
	if( info_level & ENTITY_INFO_CLASS )
	{
		GetEntityClassname(entity, sClass, sizeof(sClass));
	}
	if( info_level & ENTITY_INFO_INDEX )
	{
		IntToString(entity, sIndex, sizeof(sIndex));
	}
	if( info_level & ENTITY_INFO_HAMMERID )
	{
		if( HasEntProp(entity, Prop_Data, "m_iHammerID") )
		{
			iHammerID = GetEntProp(entity, Prop_Data, "m_iHammerID");
		}
	}
	if(bIsNetwork)
	{
		FormatEx(result, sizeof(result), "(%4d) - %32s. Name: %4s. Model: %4s. Origin: %.1f %.1f %.1f %s%s HammerId: %6i", 
					entity, sClass, sName, sModel, pos[0], pos[1], pos[2], sIndex[0] != 0 ? sIndex : "", IsInSafeRoom(entity) ? " (IN SAFEROOM)" : "", iHammerID);
	}
	else
	{
		int index = EntRefToEntIndex(entity);
		FormatEx(result, sizeof(result), "(%4d) - %32s. Name: %4s. Model: %4s. Origin: %.1f %.1f %.1f %s%s HammerId: %6i", 
					index, sClass, sName, sModel, pos[0], pos[1], pos[2], sIndex[0] != 0 ? sIndex : "", IsInSafeRoom(entity) ? " (IN SAFEROOM)" : "", iHammerID);
	}
	return result;
}

/*bool StringMap_ContainsKey(StringMap hMap, char[] sKey)
{
	int value;
	return hMap.GetValue (sKey, value);
}*/

void ReportClientWeapon()
{
	LogTo("\n***********************" ...
			"     WEAPON REPORT     " ...
			"***********************");
	LogTo("\n{Spectators}");
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 1 )
		{
			LogTo("%i. %N", i, i);
		}
	}
	LogTo("\n{Team 2}");
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 )
		{
			LogTo("%i. %N%s%s", i, i, IsFakeClient(i) ? " (BOT)" : "", IsPlayerAlive(i) ? "" : " (DEAD)");
			if( IsPlayerAlive(i))
			{
				WeaponInfo(i);
			}
		}
	}
	LogTo("\n{Team 3}");
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 3 )
		{
			LogTo("%i. %N%s%s", i, i, IsFakeClient(i) ? " (BOT)" : "", IsPlayerAlive(i) ? "" : " (DEAD)");
		}
	}
}

void WeaponInfo(int client)
{
	int weapon;
	char sName[32];
	for( int i = 0; i < 5; i++ )
	{
		weapon = GetPlayerWeaponSlot(client, i);
		
		if( weapon == -1 )
		{
			LogTo("Slot #%i: EMPTY", i);
		}
		else {
			GetEntityClassname(weapon, sName, sizeof(sName));
			LogTo("Slot #%i: %s", i, sName);
		}
	}
}

void ReportPrecacheInfo()
{
	LogTo("\n***********************" ...
			"     STRINGTABLE     " ...
			"***********************\n");
	
	int iTable = FindStringTable("modelprecache");
	if( iTable != INVALID_STRING_TABLE )
	{
		int iNum = GetStringTableNumStrings(iTable);
		LogTo("'modelprecache' count: %i", iNum);
	}
}

bool IsInSafeRoom(int entity)
{
	if(!g_bL4D) return false;

	if(entity > 0 && entity <= MaxClients && IsClientInGame(entity))
	{
		if(L4D_IsInFirstCheckpoint(entity)) return true;
		if(L4D_IsInLastCheckpoint(entity)) return true;
	}
	else
	{
		float vecPos[3];
		if( HasEntProp(entity, Prop_Send, "m_vecOrigin") )
		{
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecPos);
		}
		else {
			return false;
		}
	
		if(L4D_IsPositionInFirstCheckpoint(vecPos)) return true;
		if(L4D_IsPositionInLastCheckpoint(vecPos)) return true;
	}

	return false;
}

void OpenLog(char[] access)
{
	g_hLog = OpenFile(g_sLogPath, access);
	if( g_hLog == null )
	{
		LogError("Failed to open or create log file: %s (access: %s)", g_sLogPath, access);
		return;
	}
}

void CloseLog()
{
	if (g_hLog) {
		g_hLog.Close();
		g_hLog = null;
	}
}

void LogTo(const char[] format, any ...)
{
	static char buffer[300];
	VFormat(buffer, sizeof(buffer), format, 2);
	if (g_hLog == null) {
		OpenLog("a+");
	}
	if (g_hLog) {
		g_hLog.WriteLine(buffer);
	}
}