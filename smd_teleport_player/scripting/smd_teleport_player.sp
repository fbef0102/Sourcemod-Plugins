#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法

#include <sourcemod>
#include <sdktools>
#include <adminmenu>

#define PLUGIN_VERSION		"1.1-2026/11/17"
#define PLUGIN_NAME			"smd_teleport_player"

public Plugin myinfo =
{
	name = "[Any] Teleport an alive player",
	author = "Harry Potter",
	description = "Teleport an alive player in game",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/profiles/76561198026784913"
}

#define CVAR_FLAGS			FCVAR_NOTIFY

#define SORT_NONE			0
#define SORT_ASC			1
#define SORT_DESC			2

float g_pos[MAXPLAYERS+1][3];

ConVar g_cvAddTopMenu, g_cvShowBots, g_cvSortAlpha, g_cvSortBots;
bool g_bAddTopMenu, g_bShowBots;
int g_iSortAlpha, g_iSortBots;

TopMenuObject hAdminTeleportItem;
bool g_bMenuAdded;
int g_iTeleportClient[MAXPLAYERS+1];

public void OnPluginStart()
{
	LoadTranslations(PLUGIN_NAME ... ".phrases");

	g_cvAddTopMenu =	CreateConVar(PLUGIN_NAME ... "_adminmenu",		"1",	"If 1, Add 'Teleport player' item in admin menu under 'Player commands' category", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvShowBots =		CreateConVar(PLUGIN_NAME ... "_bots",			"1",	"If 1, Show bots in the 'Teleport player' menus", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_cvSortAlpha =		CreateConVar(PLUGIN_NAME ... "_sort_alpha",		"1",	"Sort names alphabetically in the 'Teleport player' menus.\n0 = Ignore, 1 = Ascending (A-Z), 2 = Descending (Z-A)", CVAR_FLAGS, true, 0.0, true, 2.0);
	g_cvSortBots =		CreateConVar(PLUGIN_NAME ... "_sort_bots",		"1",	"Sort bots in the 'Teleport player' menus. Applied before the alphabetical sort.\n0 = Ignore, 1 = Ascending (humans first, bots last), 2 = Descending (bots first, humans last)", CVAR_FLAGS, true, 0.0, true, 2.0);
	AutoExecConfig(true, PLUGIN_NAME);

	GetCvars();
	g_cvAddTopMenu.AddChangeHook(OnCvarAddTopMenuChanged);
	g_cvShowBots.AddChangeHook(OnCvarShowBotsChanged);
	g_cvSortAlpha.AddChangeHook(OnCvarSortAlphaChanged);
	g_cvSortBots.AddChangeHook(OnCvarSortBotsChanged);

	RegAdminCmd("sm_teleport", sm_teleport, ADMFLAG_BAN, "Open 'Teleport player' menu");
	RegAdminCmd("sm_tp", sm_teleport, ADMFLAG_BAN, "Open 'Teleport player' menu");

	if(g_bAddTopMenu)
	{
		TopMenu topmenu;
		if(LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
		{
			OnAdminMenuReady(topmenu);
		}
	}
}

void OnCvarAddTopMenuChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();

	if(g_bAddTopMenu)
	{
		TopMenu topmenu;
		if(LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
		{
			OnAdminMenuReady(topmenu);
		}
	}
	else
	{
		RemoveAdminItem();
	}
}

void OnCvarShowBotsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bShowBots = g_cvShowBots.BoolValue;
}

void OnCvarSortAlphaChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iSortAlpha = g_cvSortAlpha.IntValue;
}

void OnCvarSortBotsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iSortBots = g_cvSortBots.IntValue;
}

void GetCvars()
{
	g_bAddTopMenu = g_cvAddTopMenu.BoolValue;
	g_bShowBots = g_cvShowBots.BoolValue;
	g_iSortAlpha = g_cvSortAlpha.IntValue;
	g_iSortBots = g_cvSortBots.IntValue;
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

	// Get endpoint for teleport
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

bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > MaxClients || !entity;
}

public void OnLibraryRemoved(const char[] name)
{
	if(strcmp(name, "adminmenu") == 0)
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
	if(hTopMenu == topmenu)
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

	if(aTopMenu != null)
	{
		hAdminMenu = TopMenu.FromHandle(aTopMenu);
	}
	else {
		if(!LibraryExists("adminmenu"))
		{
			return;
		}
		if(null == (hAdminMenu = GetAdminTopMenu()))
		{
			return;
		}
	}

	if(g_bMenuAdded)
	{
		if((bRemoveItem || !g_bAddTopMenu) && hAdminTeleportItem != INVALID_TOPMENUOBJECT)
		{
			hAdminMenu.Remove(hAdminTeleportItem);
			g_bMenuAdded = false;
		}
	}
	else {
		if(g_bAddTopMenu)
		{
			TopMenuObject hMenuCategory = hAdminMenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);

			if(hMenuCategory)
			{
				hAdminTeleportItem = hAdminMenu.AddItem("SM_TeleportPlayer_Item", AdminMenuTeleportHandler, hMenuCategory, "sm_teleport", ADMFLAG_BAN, "Teleport an alive player at your crosshair");
				g_bMenuAdded = true;
			}
		}
	}
}

void AdminMenuTeleportHandler(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if(action == TopMenuAction_SelectOption)
	{
		MenuClientsToTeleport(param);
	}
	else if(action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "%T", "wind_1", param);
	}
}

void MenuClientsToTeleport(int client, int item = 0)
{
	g_iTeleportClient[client] = 0;

	Menu menu = new Menu(MenuHandler_MenuList, MENU_ACTIONS_DEFAULT);
	menu.SetTitle("%T", "wind_2", client);

	static char sId[16], name[128];
	bool bNoOneAlive = true;

	if(IsPlayerAlive(client))
	{
		FormatEx(sId, sizeof sId, "%i", GetClientUserId(client));
		FormatEx(name, sizeof name, "%T", "wind_16", client);

		menu.AddItem(sId, name);
		bNoOneAlive = false;
	}

	int[] clients = new int[MaxClients];
	int count = GetMenuClients(clients, client);

	for(int i = 0; i < count; i++)
	{
		FormatEx(sId, sizeof sId, "%i", GetClientUserId(clients[i]));
		FormatEx(name, sizeof name, "%N", clients[i]);

		menu.AddItem(sId, name);
	}

	if(count > 0)
	{
		bNoOneAlive = false;
	}

	if(bNoOneAlive)
	{
		char sText[64];
		FormatEx(sText, sizeof(sText), "%T", "wind_3", client);
		menu.AddItem("1.", sText);
	}
	menu.ExitBackButton = true;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

int MenuHandler_MenuList(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && hTopMenu)
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

			if(target && IsClientInGame(target) && IsPlayerAlive(target))
			{
				g_iTeleportClient[client] = UserId;
				MenuTeleportToClients(client, target);

				return 0;
			}

			PrintToChat(client, "[TS] %T", "wind_4", client);
			MenuClientsToTeleport(client, menu.Selection);
		}
	}

	return 0;
}

void MenuTeleportToClients(int client, int target, int item = 0)
{
	Menu menu = new Menu(MenuHandler_MenuList2, MENU_ACTIONS_DEFAULT);
	menu.SetTitle("%T", "wind_5", client);

	static char sId[16], name[128];
	char sText[64];
	FormatEx(sText, sizeof(sText), "%T", "wind_6", client);
	menu.AddItem("crosshair", sText);
	if(target != client)
	{
		FormatEx(sText, sizeof(sText), "%T", "wind_7", client);
		menu.AddItem("self", sText);
	}

	int[] clients = new int[MaxClients];
	int count = GetMenuClients(clients, client, target);

	for(int i = 0; i < count; i++)
	{
		FormatEx(sId, sizeof sId, "%i", GetClientUserId(clients[i]));
		FormatEx(name, sizeof name, "%N", clients[i]);

		menu.AddItem(sId, name);
	}

	menu.ExitBackButton = true;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

int MenuHandler_MenuList2(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack && hTopMenu)
			{
				MenuClientsToTeleport(param1);
			}
		}
		case MenuAction_Select:
		{
			int client = param1;
			int ItemIndex = param2;
			int target = GetClientOfUserId(g_iTeleportClient[client]);

			if(target && IsClientInGame(target) && IsPlayerAlive(target))
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
					if(player && IsClientInGame(player) && IsPlayerAlive(player))
					{
						GetClientAbsOrigin(player, g_pos[client]);
						canTeleport = true;
					}
					else
					{
						PrintToChat(client, "[TS] %T", "wind_11", client);
						MenuTeleportToClients(client, target, menu.Selection);

						return 0;
					}
				}

				if(canTeleport)
				{
					PerformTeleport(client, target, g_pos[client]);
					PrintToChat(client, "[TS] %T", "wind_12", client, target);
				}
				else
				{
					PrintToChat(client, "[TS] %T", "wind_13", client, g_iTeleportClient[client]);
				}
			}
			else
			{
				PrintToChat(client, "[TS] %T", "wind_14", client);
			}

			MenuClientsToTeleport(client);
		}
	}

	return 0;
}

int GetMenuClients(int[] clients, int exclude1, int exclude2 = 0)
{
	int count;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(i == exclude1 || i == exclude2) continue;
		if(!IsClientInGame(i)) continue;
		if(!IsPlayerAlive(i)) continue;
		if(IsFakeClient(i) && !g_bShowBots) continue;

		clients[count++] = i;
	}

	if((g_iSortAlpha != SORT_NONE || g_iSortBots != SORT_NONE) && count > 1)
	{
		SortCustom1D(clients, count, SortMenuClients);
	}

	return count;
}

int SortMenuClients(int elem1, int elem2, const int[] array, Handle hndl)
{
	int result;

	if(g_iSortBots != SORT_NONE)
	{
		bool bIsBot1 = IsFakeClient(elem1);
		bool bIsBot2 = IsFakeClient(elem2);

		if(bIsBot1 != bIsBot2)
		{
			result = bIsBot1 ? 1 : -1;
			return g_iSortBots == SORT_DESC ? -result : result;
		}
	}

	if(g_iSortAlpha != SORT_NONE)
	{
		char sName1[MAX_NAME_LENGTH], sName2[MAX_NAME_LENGTH];
		GetClientName(elem1, sName1, sizeof sName1);
		GetClientName(elem2, sName2, sizeof sName2);

		result = strcmp(sName1, sName2, false);
		if(result != 0)
		{
			return g_iSortAlpha == SORT_DESC ? -result : result;
		}
	}

	// Keep client index order as tiebreaker
	return elem1 - elem2;
}
