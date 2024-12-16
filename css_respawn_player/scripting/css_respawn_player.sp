#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <adminmenu>
#include <cstrike>
#define PLUGIN_VERSION			"1.1"
#define PLUGIN_NAME			    "css_respawn_player"
#define DEBUG 0

#define CVAR_FLAGS	FCVAR_NOTIFY

public Plugin myinfo =
{
	name = "[CSS] SM Respawn Player",
	author = "HarryPotter",
	description = "Allows players to be respawned at one's crosshair.",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/profiles/76561198026784913/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();

	if( test != Engine_CSS )
	{
		strcopy(error, err_max, "Plugin only supports CSS.");
		return APLRes_SilentFailure;
	}

	CreateNative("SM_CSS_Respawn", NATIVE_Respawn);

	return APLRes_Success;
}


#define CVAR_FLAGS                    FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION     FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY
#define ACCESS_FLAG ADMFLAG_BAN

#define TRANSLATION_FILE		PLUGIN_NAME ... ".phrases"

float VEC_DUMMY[3]	= {99999.0, 99999.0, 99999.0};

ConVar g_cvLoadout, g_cvArmor, g_cvShowAction, g_cvAddTopMenu, g_cvDestination;
char g_sLoadout[256];
bool g_bArmor, g_bShowAction, g_bAddTopMenu;
int g_iDestination;

bool g_bMenuAdded;

TopMenuObject hAdminSpawnItem;

public void OnPluginStart()
{
	LoadTranslations( "common.phrases");
	LoadTranslations( TRANSLATION_FILE);
	
	g_cvLoadout = 		CreateConVar( PLUGIN_NAME ... "_loadout", 		"weapon_knife,weapon_glock,weapon_mp5navy", 	"Respawn players with this loadout, separate by commas", CVAR_FLAGS);
	g_cvArmor = 		CreateConVar( PLUGIN_NAME ... "_armor", 		"1", 				"If 1, Give Kevlar Suit and a Helmet when repsawn player", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvShowAction = 	CreateConVar( PLUGIN_NAME ... "_showaction", 	"1", 		  	  	"If 1, Notify in chat and log action about respawn?", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvDestination = 	CreateConVar( PLUGIN_NAME ... "_destination", 	"0", 		  		"After respawn player, teleport player to 0=Crosshair, 1=Self (You must be alive).", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvAddTopMenu = 	CreateConVar( PLUGIN_NAME ... "_adminmenu", 	"1", 	 	  		"If 1, Add 'Respawn player' item in admin menu under 'Player commands' category", CVAR_FLAGS, true, 0.0, true, 1.0);
	CreateConVar(                     PLUGIN_NAME ... "_version",     PLUGIN_VERSION, PLUGIN_NAME ... " Plugin Version", CVAR_FLAGS_PLUGIN_VERSION);
	AutoExecConfig(true, 			  PLUGIN_NAME);
	
	GetCvars();
	g_cvLoadout.AddChangeHook(ConVarChanged_Cvars);
	g_cvArmor.AddChangeHook(ConVarChanged_Cvars);
	g_cvShowAction.AddChangeHook(ConVarChanged_Cvars);
	g_cvDestination.AddChangeHook(ConVarChanged_Cvars);
	g_cvAddTopMenu.AddChangeHook(OnCvarChanged_AddTopMenu);

	RegAdminCmd("sm_respawn", 		CmdRespawn, 	ACCESS_FLAG, "<opt.target> Respawn a player at your crosshair. Without argument - opens menu to select players");
	
	if(g_bAddTopMenu)
	{
		TopMenu topmenu;
		if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
		{
			OnAdminMenuReady(topmenu);
		}
	}
}

//-------------------------------Cvars-------------------------------


void ConVarChanged_Cvars(ConVar hCvar, const char[] sOldVal, const char[] sNewVal)
{
	GetCvars();
}

void OnCvarChanged_AddTopMenu(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
	if( g_bAddTopMenu )
	{
		TopMenu topmenu;
		if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
		{
			OnAdminMenuReady(topmenu);
		}
	}
	else
	{
		RemoveAdminItem();
	}
}

void GetCvars()
{
	g_cvLoadout.GetString(g_sLoadout, sizeof g_sLoadout);
	g_bArmor = g_cvArmor.BoolValue;
	g_bShowAction = g_cvShowAction.BoolValue;
	g_iDestination = g_cvDestination.IntValue;
	g_bAddTopMenu = g_cvAddTopMenu.BoolValue;
}

public void OnLibraryRemoved(const char[] name)
{
	if( strcmp(name, "adminmenu") == 0 )
	{
		g_bMenuAdded = false;
		hAdminSpawnItem = INVALID_TOPMENUOBJECT;
	}
}

TopMenu hTopMenu;
public void OnAdminMenuReady(Handle aTopMenu)
{
	AddAdminItem(aTopMenu);

	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);

	/* Block us from being called twice */
	if (hTopMenu == topmenu)
	{
		return;
	}

	hTopMenu = topmenu;
}

stock void RemoveAdminItem()
{
	AddAdminItem(null, true);
}

void AddAdminItem(Handle aTopMenu, bool bRemoveItem = false)
{
	TopMenu hAdminMenu;
	
	if( aTopMenu != null )
	{
		hAdminMenu = TopMenu.FromHandle(aTopMenu);
	}
	else {
		if( !LibraryExists("adminmenu") )
		{
			return;
		}	
		if( null == (hAdminMenu = GetAdminTopMenu()) )
		{
			return;
		}
	}
	
	if( g_bMenuAdded )
	{
		if( (bRemoveItem || !g_cvAddTopMenu.BoolValue) && hAdminSpawnItem != INVALID_TOPMENUOBJECT )
		{
			hAdminMenu.Remove(hAdminSpawnItem);
			g_bMenuAdded = false;
		}
	}
	else 
	{
		if( g_cvAddTopMenu.BoolValue )
		{
			TopMenuObject hMenuCategory = hAdminMenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);

			if( hMenuCategory )
			{
				hAdminSpawnItem = hAdminMenu.AddItem("CSS_SM_RespawnPlayer_Item", AdminMenuSpawnHandler, hMenuCategory, "sm_respawn", ACCESS_FLAG, "Respawn a player at your crosshair");
				g_bMenuAdded = true;
			}
		}
	}
}

public void AdminMenuSpawnHandler(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if( action == TopMenuAction_SelectOption )
	{
		MenuClientsToSpawn(param);
	}
	else if( action == TopMenuAction_DisplayOption )
	{
		FormatEx(buffer, maxlength, "%T", "Respawn_Player", param);
	}
}

void MenuClientsToSpawn(int client, int item = 0)
{
	Menu menu = new Menu(MenuHandler_MenuList, MENU_ACTIONS_DEFAULT);
	menu.SetTitle("%T", "List_Players", client);
	
	static char sId[16], name[64];
	bool bNoOneDead = true;

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i))
		{
			if(IsPlayerAlive(i)) continue;
			if(GetClientTeam(i) != CS_TEAM_T) continue;
			
			FormatEx(sId, sizeof sId, "%i", GetClientUserId(i));
			if(IsFakeClient(i)) FormatEx(name, sizeof name, "(T-Bot) %N", i);
			else FormatEx(name, sizeof name, "(T) %N", i);
			
			menu.AddItem(sId, name);

			bNoOneDead = false;
		}
	}

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i))
		{
			if(IsPlayerAlive(i)) continue;
			if(GetClientTeam(i) != CS_TEAM_CT) continue;
			
			FormatEx(sId, sizeof sId, "%i", GetClientUserId(i));
			if(IsFakeClient(i)) FormatEx(name, sizeof name, "(CT-Bot) %N", i);
			else FormatEx(name, sizeof name, "(CT) %N", i);
			
			menu.AddItem(sId, name);
		}

		bNoOneDead = false;
	}

	if(bNoOneDead)
	{
		char sText[64];
		FormatEx(sText, sizeof(sText), "%T", "No Any Dead Survivor", client);
		menu.AddItem("1.", sText);
	}

	menu.ExitBackButton = true;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

public int MenuHandler_MenuList(Menu menu, MenuAction action, int param1, int param2)
{
	switch( action )
	{
		case MenuAction_End:
			delete menu;

		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && hTopMenu)
			{
				hTopMenu.Display(param1, TopMenuPosition_LastCategory);
			}
		}
		
		case MenuAction_Select:
		{
			int client = param1;
			int ItemIndex = param2;
			
			static char sUserId[16];
			menu.GetItem(ItemIndex, sUserId, sizeof sUserId);
			
			int UserId = StringToInt(sUserId);
			int target = GetClientOfUserId(UserId);
			
			if( target && IsClientInGame(target) )
			{
				vRespawnPlayer(client, target);
			}
			MenuClientsToSpawn(client, menu.Selection);
		}
	}

	return 0;
}

public int NATIVE_Respawn(Handle plugin, int numParams)
{
	if( numParams < 1 )
		ThrowNativeError(SP_ERROR_PARAM, "Invalid numParams");
	
	int iTarget = GetNativeCell(1);
	int iClient;
	float vec[3];
	vec = VEC_DUMMY;
	
	if( numParams >= 2 )
	{
		iClient = GetNativeCell(2);
	}
	if( numParams >= 3 )
	{
		GetNativeArray(3, vec, 3);
	}
	return vRespawnPlayer(iClient, iTarget, vec);
}

public Action CmdRespawnMenu(int client, int args)
{
	MenuClientsToSpawn(client);
	return Plugin_Handled;
}

public Action CmdRespawn(int client, int args)
{
	if( args < 1 )
	{
		if( GetCmdReplySource() == SM_REPLY_TO_CONSOLE )
		{
			PrintToConsole(client, "[SM] Usage: sm_respawn <player1> [player2] ... [playerN] - respawn all listed players");
		}
		CmdRespawnMenu(client, 0);
		return Plugin_Handled;
	}
	char arg1[MAX_TARGET_LENGTH], target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count, target;
	bool tn_is_ml;
	
	GetCmdArg(1, arg1, sizeof arg1);
	if( (target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof target_name, tn_is_ml)) <= 0 )
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for( int i = 0; i < target_count; i++ )
	{
		target = target_list[i];
		
		if( target && IsClientInGame(target) )
		{
			vRespawnPlayer(client, target);
		}
	}
	return Plugin_Handled;
}

bool vRespawnPlayer(int client, int target, float vec[3] = {99999.0, 99999.0, 99999.0})
{
	float ang[3];
	
	if( vec[0] == VEC_DUMMY[0] && vec[1] == VEC_DUMMY[1] && vec[2] == VEC_DUMMY[2] )
	{
		if(g_iDestination == 0 && GetSpawnEndPoint(client, vec))
		{
			//nothing
		}
		else if(g_iDestination == 1)
		{
			GetClientAbsOrigin(client, vec);
		}
	}

	if( client )
	{
		GetClientEyeAngles(client, ang);
	}

	switch( GetClientTeam(target) )
	{
		case CS_TEAM_T:
		{
			if(IsPlayerAlive(target))
			{
				PrintToChat(client, "[SM] %T", "message_1", client, target);
				return false;
			}

			CS_RespawnPlayer(target);
			vPerformTeleport(client, target, vec, ang);
			
			char sItems[6][64];
			if(strlen(g_sLoadout) > 0)
			{
				StripWeapons( target );

				ExplodeString(g_sLoadout, ",", sItems, sizeof sItems, sizeof sItems[]);
				
				for( int iItem = 0; iItem < sizeof sItems; iItem++ )
				{
					if ( sItems[iItem][0] != '\0' )
					{
						vCheatCommand(target, "give", sItems[iItem]);
					}
				}
			}

			if(g_bArmor)
			{
				GivePlayerItem(target, "item_assaultsuit");
			}
		}
		
		case CS_TEAM_CT:
		{
			if(IsPlayerAlive(target))
			{
				PrintToChat(client, "[SM] %T", "message_1", client, target);
				return false;
			}

			CS_RespawnPlayer(target);
			vPerformTeleport(client, target, vec, ang);
		
			char sItems[6][64];
			if(strlen(g_sLoadout) > 0)
			{
				StripWeapons( target );

				ExplodeString(g_sLoadout, ",", sItems, sizeof sItems, sizeof sItems[]);
				
				for( int iItem = 0; iItem < sizeof sItems; iItem++ )
				{
					if ( sItems[iItem][0] != '\0' )
					{
						vCheatCommand(target, "give", sItems[iItem]);
					}
				}
			}
			
			if(g_bArmor)
			{
				GivePlayerItem(target, "item_assaultsuit");
			}
		}
		
		case CS_TEAM_SPECTATOR:
		{
			PrintToChat(client, "[SM] %T", "message_3", client, target);
			return false;
		}

		default:
		{
			PrintToChat(client, "[SM] %T", "message_2", client, target);
			return false;
		}
	}
	
	return true;
}

public bool bTraceEntityFilterPlayer(int entity, int contentsMask)
{
	return (entity > MaxClients);
}

bool GetSpawnEndPoint(int client, float vSpawnVec[3])
{
	if( !client )
	{
		return false;
	}
	float vEnd[3], vEye[3];
	if( GetDirectionEndPoint(client, vEnd) )
	{
		GetClientEyePosition(client, vEye);
		ScaleVectorDirection(vEye, vEnd, 0.1); // to allow collision to be happen
		
		if( GetNonCollideEndPoint(client, vEnd, vSpawnVec) )
		{
			return true;
		}
	}

	return false;
}

void ScaleVectorDirection(float vStart[3], float vEnd[3], float fMultiple)
{
    float dir[3];
    SubtractVectors(vEnd, vStart, dir);
    ScaleVector(dir, fMultiple);
    AddVectors(vEnd, dir, vEnd);
}

stock bool GetDirectionEndPoint(int client, float vEndPos[3])
{
	float vDir[3], vPos[3];
	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vDir);
	
	Handle hTrace = TR_TraceRayFilterEx(vPos, vDir, MASK_PLAYERSOLID, RayType_Infinite, bTraceEntityFilterPlayer, client);
	if( hTrace != INVALID_HANDLE )
	{
		if( TR_DidHit(hTrace) )
		{
			TR_GetEndPosition(vEndPos, hTrace);
			delete hTrace;
			return true;
		}
		delete hTrace;
	}
	return false;
}

stock bool GetNonCollideEndPoint(int client, float vEnd[3], float vEndNonCol[3])
{
	float vMin[3], vMax[3], vStart[3];
	GetClientEyePosition(client, vStart);
	GetClientMins(client, vMin);
	GetClientMaxs(client, vMax);
	vStart[2] += 20.0; // if nearby area is irregular
	Handle hTrace = TR_TraceHullFilterEx(vStart, vEnd, vMin, vMax, MASK_PLAYERSOLID, bTraceEntityFilterPlayer, client);
	if( hTrace != INVALID_HANDLE )
	{
		if( TR_DidHit(hTrace) )
		{
			TR_GetEndPosition(vEndNonCol, hTrace);
			delete hTrace;
			return true;
		}
		delete hTrace;
	}
	return false;
}

void vPerformTeleport(int client, int target, float pos[3], float ang[3])
{
	pos[2] += 5.0;
	TeleportEntity(target, pos, ang, NULL_VECTOR);

	if( g_bShowAction && client )
	{
		LogAction(client, target, "\"%L\" teleported \"%L\" after respawning him" , client, target);
	}
}

void vCheatCommand(int client, char[] command, char[] arguments = "")
{
	int iCmdFlags = GetCommandFlags(command);
	SetCommandFlags(command, iCmdFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, iCmdFlags | GetCommandFlags(command));
}

void StripWeapons(int client) // strip all items from client
{
	int itemIdx;
	for (int x = 0; x <= 4; x++)
	{
		if((itemIdx = GetPlayerWeaponSlot(client, x)) != -1)
		{  
			RemovePlayerItem(client, itemIdx);
			AcceptEntityInput(itemIdx, "Kill");
		}
	}
}