#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法
#include <sourcemod>
#include <sdktools>
#include <adminmenu>
#include <cstrike>
#define PLUGIN_VERSION			"1.0"
#define PLUGIN_NAME			    "css_teleport_player"
#define DEBUG 0

public Plugin myinfo = 
{
	name = "[CSS] Teleport an alive player",
	author = "Harry Potter",
	description = "Teleport an alive player in game",
	version = "1.0",
	url = "https://steamcommunity.com/profiles/76561198026784913"
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

#define CVAR_FLAGS	FCVAR_NOTIFY

float g_pos[MAXPLAYERS+1][3];

ConVar g_cvAddTopMenu;
bool g_bAddTopMenu;

TopMenuObject hAdminTeleportItem;
bool g_bMenuAdded;
int g_iTelpeortClient[MAXPLAYERS+1];

public void OnPluginStart()
{
	LoadTranslations(PLUGIN_NAME ... ".phrases");

	g_cvAddTopMenu = 	CreateConVar( PLUGIN_NAME ... "adminmenu", 			"1", 	"If 1, Add 'Teleport player' item in admin menu under 'Player commands' category", CVAR_FLAGS, true, 0.0, true, 1.0);
	AutoExecConfig(true, PLUGIN_NAME);

	GetCvars();
	g_cvAddTopMenu.AddChangeHook(OnCvarTopMenuChanged);

	RegAdminCmd("sm_teleport", sm_teleport, ADMFLAG_BAN, "Open 'Teleport player' menu");
	RegAdminCmd("sm_tp", sm_teleport, ADMFLAG_BAN, "Open 'Teleport player' menu");

	if(g_bAddTopMenu)
	{
		TopMenu topmenu;
		if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
		{
			OnAdminMenuReady(topmenu);
		}
	}
}

void OnCvarTopMenuChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();

	if(g_bAddTopMenu)
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
	g_bAddTopMenu = g_cvAddTopMenu.BoolValue;
}

Action sm_teleport(int client, int args)
{
	if(client == 0) return Plugin_Handled;
	
	MenuClientsToTeleport(client);

	return Plugin_Handled;
}

bool SetTeleportEndPoint(int client, float vPos[3])
{
	float vAngles[3],vOrigin[3];
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	//get endpoint for teleport
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	
	if(TR_DidHit(trace))
	{
		float vBuffer[3],vStart[3];

		TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		float Distance = -35.0;
		GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		vPos[0] = vStart[0] + (vBuffer[0]*Distance);
		vPos[1] = vStart[1] + (vBuffer[1]*Distance);
		vPos[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else
	{
		PrintToChat(client, "[TS] Could not find %N's crosshair location.", client);
		delete trace;
		return false;
	}

	delete trace;
	return true;
}

void PerformTeleport(int client, int target, float pos[3], bool addbot = false)
{
	pos[2] += 5.0;
	TeleportEntity(target, pos, NULL_VECTOR, NULL_VECTOR);
	
	if(addbot)
	{
		LogAction(client,target, "\"%L\" teleported \"%L\" after respawn him (New bot)." , client, target);
	}
	else
	{
		LogAction(client,target, "\"%L\" teleported \"%L\"" , client, target);
	}
}

public Action Timer_KickFakeBot(Handle timer, int fakeclient)
{
	if(IsClientConnected(fakeclient))
	{
		KickClient(fakeclient, "Kicking FakeClient");	
		return Plugin_Stop;
	}	
	return Plugin_Continue;
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > MaxClients || !entity;
} 

public void OnLibraryRemoved(const char[] name)
{
	if( strcmp(name, "adminmenu") == 0 )
	{
		g_bMenuAdded = false;
		hAdminTeleportItem = INVALID_TOPMENUOBJECT;
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

void RemoveAdminItem()
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
		if( (bRemoveItem || !g_bAddTopMenu) && hAdminTeleportItem != INVALID_TOPMENUOBJECT )
		{
			hAdminMenu.Remove(hAdminTeleportItem);
			g_bMenuAdded = false;
		}
	}
	else {
		if( g_bAddTopMenu )
		{
			TopMenuObject hMenuCategory = hAdminMenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);

			if( hMenuCategory )
			{
				hAdminTeleportItem = hAdminMenu.AddItem("CSS_SM_TeleportPlayer_Item", AdminMenuTeleportHandler, hMenuCategory, "sm_teleport", ADMFLAG_BAN, "Teleport an alive player at your crosshair");
				g_bMenuAdded = true;
			}
		}
	}
}

public void AdminMenuTeleportHandler(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if( action == TopMenuAction_SelectOption )
	{
		MenuClientsToTeleport(param);
	}
	else if( action == TopMenuAction_DisplayOption )
	{
		FormatEx(buffer, maxlength, "%T", "css_wind_1", param);
	}
}

void MenuClientsToTeleport(int client, int item = 0)
{
	g_iTelpeortClient[client] = 0;

	Menu menu = new Menu(MenuHandler_MenuList, MENU_ACTIONS_DEFAULT);
	menu.SetTitle("%T", "css_wind_2", client);

	static char sId[16], name[128];
	bool bNoOneAlive = true;

	if(IsPlayerAlive(client) && GetClientTeam(client) > 0)
	{
		FormatEx(sId, sizeof sId, "%i", GetClientUserId(client));
		FormatEx(name, sizeof name, "%T", "css_wind_16", client);

		menu.AddItem(sId, name);
		bNoOneAlive = false;
	}

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i))
		{
			if(i == client) continue;
			if(!IsPlayerAlive(i)) continue;
			if(GetClientTeam(i) != CS_TEAM_T) continue;
			
			FormatEx(sId, sizeof sId, "%i", GetClientUserId(i));
			if(IsFakeClient(i)) FormatEx(name, sizeof name, "(T-Bot) %N", i);
			else FormatEx(name, sizeof name, "(T) %N", i);
			
			menu.AddItem(sId, name);
			
			bNoOneAlive = false;
		}
	}

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i))
		{
			if(i == client) continue;
			if(!IsPlayerAlive(i)) continue;
			if(GetClientTeam(i) != CS_TEAM_CT) continue;
			
			FormatEx(sId, sizeof sId, "%i", GetClientUserId(i));
			if(IsFakeClient(i)) FormatEx(name, sizeof name, "(CT-Bot) %N", i);
			else FormatEx(name, sizeof name, "(CT) %N", i);
			
			menu.AddItem(sId, name);
			
			bNoOneAlive = false;
		}
	}


	if(bNoOneAlive)
	{
		char sText[64];
		FormatEx(sText, sizeof(sText), "%T", "css_wind_3", client);
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
		{
			delete menu;
		}
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
			
			char sUserId[16];
			menu.GetItem(ItemIndex, sUserId, sizeof sUserId);
			
			int UserId = StringToInt(sUserId);
			int target = GetClientOfUserId(UserId);
			
			if( target && IsClientInGame(target) && IsPlayerAlive(target))
			{
				g_iTelpeortClient[client] = UserId;
				MenuTeleportToClients(client, target);

				return 0;
			}
			
			PrintToChat(client, "[TS] %T", "css_wind_4", client);
			MenuClientsToTeleport(client, menu.Selection);
		}
	}

	return 0;
}

void MenuTeleportToClients(int client, int target, int item = 0)
{
	Menu menu = new Menu(MenuHandler_MenuList2, MENU_ACTIONS_DEFAULT);
	menu.SetTitle("%T", "css_wind_5", client);

	static char sId[16], name[128];
	char sText[64];
	FormatEx(sText, sizeof(sText), "%T", "css_wind_6", client);
	menu.AddItem("crosshair", sText);
	if(target != client)
	{
		FormatEx(sText, sizeof(sText), "%T", "css_wind_7", client);
		menu.AddItem("self", sText);
	}
	
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i))
		{
			if(i == client) continue;
			if(i == target) continue;
			if(!IsPlayerAlive(i)) continue;
			if(GetClientTeam(i) != CS_TEAM_T) continue;
			
			FormatEx(sId, sizeof sId, "%i", GetClientUserId(i));
			if(IsFakeClient(i)) FormatEx(name, sizeof name, "(T-Bot) %N", i);
			else FormatEx(name, sizeof name, "(T) %N", i);
			
			menu.AddItem(sId, name);
		}
	}


	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i))
		{
			if(i == client) continue;
			if(i == target) continue;
			if(!IsPlayerAlive(i)) continue;
			if(GetClientTeam(i) != CS_TEAM_CT) continue;
			
			FormatEx(sId, sizeof sId, "%i", GetClientUserId(i));
			if(IsFakeClient(i)) FormatEx(name, sizeof name, "(CT-Bot) %N", i);
			else FormatEx(name, sizeof name, "(CT) %N", i);
			
			menu.AddItem(sId, name);
		}
	}

	menu.ExitBackButton = true;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

public int MenuHandler_MenuList2(Menu menu, MenuAction action, int param1, int param2)
{
	switch( action )
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && hTopMenu)
			{
				MenuClientsToTeleport(param1);
			}
		}
		case MenuAction_Select:
		{
			int client = param1;
			int ItemIndex = param2;
			int target = GetClientOfUserId(g_iTelpeortClient[client]);

			if( target && IsClientInGame(target) && IsPlayerAlive(target))
			{
				char sUserId[16];
				menu.GetItem(ItemIndex, sUserId, sizeof sUserId);
				bool canTeleport = false;
				if(strcmp(sUserId, "crosshair", false) == 0)
				{
					if(SetTeleportEndPoint(client, g_pos[client]))
					{
						canTeleport = true;
					}
				}
				else if(strcmp(sUserId, "self", false) == 0)
				{
					GetClientAbsOrigin(client, g_pos[client]);
					canTeleport = true;
				}
				else
				{
					int player = GetClientOfUserId(StringToInt(sUserId));
					if( player && IsClientInGame(player) && IsPlayerAlive(player))
					{
						GetClientAbsOrigin(player, g_pos[client]);
						canTeleport = true;
					}
					else
					{
						PrintToChat(client, "[TS] %T", "css_wind_11", client);
						MenuTeleportToClients(client, target, menu.Selection);

						return 0;
					}
				}

				if(canTeleport)
				{
					PerformTeleport(client, target, g_pos[client]);
					PrintToChat(client, "[TS] %T", "css_wind_12", client, target);
				}
				else
				{
					PrintToChat(client, "[TS] %T", "css_wind_13", client, g_iTelpeortClient[client]);
				}
			}
			else
			{
				PrintToChat(client, "[TS] %T", "css_wind_14", client);
			}

			MenuClientsToTeleport(client);
		}
	}

	return 0;
}