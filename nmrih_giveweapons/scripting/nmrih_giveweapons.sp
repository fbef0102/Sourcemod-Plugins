#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <adminmenu>

#define PLUGIN_VERSION "1.1h-2025/2/20"
#define PLUGIN_MSG_PREFIX "[NMP-GW] "

#define PATH_ITEMS_DATA "data/nmrih_giveweapons.txt"

#define SPAWNITEM_DISTANCE		100.0
#define SPAWNITEM_OFFSET		15.0

#define ADMINMENU_GIVE_ITEM		0
#define ADMINMENU_GIVE_TARGET	1
#define ADMINMENU_SPAWN_ITEM	2
#define ADMINMENU_SPAWN_TARGET	3

#define ADMINMENU_NEW_CATEGORY	1


enum
{
	FindItem_FoundNothing = 0,
	FindItem_InvalidArg = -1,
	FindItem_NoAccess = -2,
	FindItem_NotAvaliable = -3
};


ConVar nmp_gw_silent = null;

bool bSilentAdmin = true;

KeyValues hItemsData = null;

TopMenu hLastTopMenu = null;
char szSelectedItem[MAXPLAYERS+1][33];

public Plugin myinfo = {
	name = "[NMRiH] Give Weapons",
	author = "Leonardo, Harry",
	description = "Give weapons and items.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=232911"
};

int g_iSelectMenuPos[MAXPLAYERS+1];

public void OnPluginStart()
{
	LoadTranslations( "core.phrases.txt" );
	LoadTranslations( "common.phrases.txt" );
	LoadTranslations( "nmrih_giveweapons.phrases.txt" );
	
	CreateConVar( "nmrih_giveweapons_version", PLUGIN_VERSION, "nmrih_giveweapons version", FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_DONTRECORD );
	HookConVarChange( nmp_gw_silent = CreateConVar( "nmrih_giveweapons_silent", bSilentAdmin ? "1" : "0", "Hide admin activity.", FCVAR_NOTIFY, true, 0.0, true, 1.0 ), OnConVarChanged );
	AutoExecConfig(true,                "nmrih_giveweapons");

	RegAdminCmd( "sm_give", Command_Give, ADMFLAG_SLAY, "Usage: sm_give <targets> <weapon|item>" );
	RegAdminCmd( "sm_spawni", Command_SpawnItem, ADMFLAG_ROOT, "Usage: sm_spawni <weapon|item> [targets|x y z]" );
	RegAdminCmd( "sm_gw_reload", Command_ReloadConfigs, ADMFLAG_ROOT );
	RegAdminCmd( "sm_gw_scan", Command_Scan, ADMFLAG_GENERIC );
	
	for( int i = 0; i <= MAXPLAYERS; i++ )
		OnClientPutInServer( i );
		
}

public void OnAllPluginsLoaded()
{
	TopMenu topmenu;
	if( LibraryExists( "adminmenu" ) && ( topmenu = GetAdminTopMenu() ) != null )
		OnAdminMenuReady( topmenu );
}

public void OnLibraryRemoved( const char[] szLibName )
{
	if( StrEqual( szLibName, "adminmenu" ) )
		hLastTopMenu = null;
}

public void OnConfigsExecuted()
{
	GetCvars();
	
	ReadItemsData();
}

public void OnClientPutInServer( int iClient )
{
	szSelectedItem[iClient][0] = '\0';
}

void OnConVarChanged(ConVar hCvar, const char[] sOldVal, const char[] sNewVal)
{
	GetCvars();
}

void GetCvars()
{
	bSilentAdmin = GetConVarBool( nmp_gw_silent );
}

Action Command_Give( int iClient, int nArgs )
{
	if( nArgs < 2 )
	{
		ReplyToCommand( iClient, "%sUsage: sm_give <targets> <weapon/item>", PLUGIN_MSG_PREFIX );
		return Plugin_Handled;
	}
	
	char szBuffer[128];
	int iTargets[MAXPLAYERS+1], nTargets;
	char szTargetName[MAX_NAME_LENGTH];
	bool bTargetNameML;
	char szClassname[32], szItemName[2][32];
	bool bItemNameIsML;
	int iMaxAmmo[2];
	
	GetCmdArg( 1, szBuffer, sizeof( szBuffer ) );
	if( ( nTargets = ProcessTargetString( szBuffer, iClient, iTargets, sizeof( iTargets ), COMMAND_FILTER_CONNECTED|COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_IMMUNITY, szTargetName, sizeof( szTargetName ), bTargetNameML ) ) <= 0 )
	{
		ReplyToTargetError( iClient, nTargets );
		return Plugin_Handled;
	}
	
	GetCmdArg( 2, szBuffer, sizeof( szBuffer ) );
	char sModel[256];
	switch( FindItemEx( iClient, szBuffer, szClassname, sizeof( szClassname ), szItemName[0], sizeof( szItemName[] ), szItemName[1], sizeof( szItemName[] ), bItemNameIsML, iMaxAmmo[0], iMaxAmmo[1],
		sModel, sizeof( sModel ) ) )
	{
		case 1: {}
		case FindItem_FoundNothing:
		{
			ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP No Matching" );
			return Plugin_Handled;
		}
		case FindItem_InvalidArg:
		{
			ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP Invalid Item Argument", szBuffer );
			return Plugin_Handled;
		}
		case FindItem_NoAccess:
		{
			ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP No Access" );
			return Plugin_Handled;
		}
		case FindItem_NotAvaliable:
		{
			ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP Cannot Give" );
			return Plugin_Handled;
		}
		default:
		{
			ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP Multiple Items" );
			return Plugin_Handled;
		}
	}
	
	//bool bBandages = StrEqual( szClassname, "item_bandages", true );
	//bool bbFirstAid = StrEqual( szClassname, "item_first_aid", true );
	//bool bbPills = StrEqual( szClassname, "item_pills", true );
	//bool bbWalkieTalkie = StrEqual( szClassname, "item_walkietalkie", true );
	
	float vecEyeOrigin[3];
	for( int iEntity, iPAmmoOffs, i = 0; i < nTargets; i++ )
	{
		iEntity = -1;
		
		/*if( bBandages )
		{
			if( GetEntProp( iTargets[i], Prop_Send, "_bandageCount" ) )
				continue;
		}
		else if( bFirstAid )
		{
			if( GetEntProp( iTargets[i], Prop_Send, "_hasFirstAidKit" ) )
				continue;
		}
		else if( bPills )
		{
			if( GetEntProp( iTargets[i], Prop_Send, "m_bHasPills" ) )
				continue;
		}
		else if( bWalkieTalkie )
		{
			if( GetEntProp( iTargets[i], Prop_Send, "m_bHasWalkieTalkie" ) )
				continue;
		}
		else for( int j = 0; j < 48; j++ )*/
		for( int j = 0; j < 48; j++ )
		{
			iEntity = GetEntPropEnt( iTargets[i], Prop_Send, "m_hMyWeapons", j );
			if( IsValidEdict( iEntity ) )
			{
				GetEntityClassname( iEntity, szBuffer, sizeof( szBuffer ) );
				if( StrEqual( szClassname, szBuffer, false ) )
					break;
			}
			iEntity = -1;
		}
		
		if( iEntity == -1 )
		{
			if(strncmp(szClassname, "item_inventory_box", 18, false) == 0)
			{
				iEntity = CreateEntityByName( "item_inventory_box" );
				if( iEntity <= MaxClients )
				{
					LogMessage( "Failed to give '%s' to player %L (by %N)", szClassname, iTargets[i], iClient );
					ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP Invalid Item Entity", szClassname );
					continue;
				}

				DispatchKeyValue(iEntity, "spawnsolid", "0");
				DispatchKeyValue(iEntity, "model", sModel);
			}
			else
			{
				iEntity = GivePlayerItem( iTargets[i], szClassname );
				if( iEntity <= MaxClients )
				{
					LogMessage( "Failed to give '%s' to player %L (by %N)", szClassname, iTargets[i], iClient );
					ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP Invalid Item Entity", szClassname );
					continue;
				}
			}
		}

		if(strncmp(szClassname, "item_inventory_box", 18, false) == 0)
		{
			DispatchSpawn( iEntity );
			GetClientEyePosition( iTargets[i], vecEyeOrigin );
			TeleportEntity( iEntity, vecEyeOrigin, NULL_VECTOR, NULL_VECTOR );
		}
		else
		{
			iPAmmoOffs = FindDataMapInfo( iTargets[i], "m_iAmmo" );
			if( iMaxAmmo[0] > 0 )
				SetEntData( iTargets[i], ( iPAmmoOffs + GetEntProp( iEntity, Prop_Data, "m_iPrimaryAmmoType" ) * 4 ), iMaxAmmo[0], _, true );
			if( iMaxAmmo[1] > 0 )
				SetEntData( iTargets[i], ( iPAmmoOffs + GetEntProp( iEntity, Prop_Data, "m_iSecondaryAmmoType" ) * 4 ), iMaxAmmo[1], _, true );
			
			AcceptEntityInput( iEntity, "Use", iTargets[i], iTargets[i] );
		}
		
		if( !bSilentAdmin && !bTargetNameML )
			ShowActivity2( iClient, PLUGIN_MSG_PREFIX, "%t", bItemNameIsML ? "NMP Activity Give 2 T" : "NMP Activity Give 2", szItemName[1], iTargets[i] );
		LogAction( iClient, iTargets[i], "gave '%s'", szClassname );
	}
	
	if( !bSilentAdmin && bTargetNameML )
		ShowActivity2( iClient, PLUGIN_MSG_PREFIX, "%t", bItemNameIsML ? "NMP Activity Give T" : "NMP Activity Give", szItemName[1], szTargetName );
	
	return Plugin_Handled;
}

Action Command_SpawnItem( int iClient, int nArgs )
{
	if( iClient < 0 || iClient > MaxClients || iClient != 0 && !IsClientInGame( iClient ) )
		return Plugin_Continue;
	
	char szBuffer[128];
	bool bOverrideCoords = false;
	int iTargets[MAXPLAYERS+1], nTargets;
	char szTargetName[MAX_NAME_LENGTH];
	bool bTargetNameML;
	char szClassname[32], szItemName[2][32];
	bool bItemNameIsML;
	int iMaxAmmo[2];
	
	float vecTarget[3], vecEyeAngles[3];
	if( nArgs == 2 )
	{
		GetCmdArg( 2, szBuffer, sizeof( szBuffer ) );
		if( ( nTargets = ProcessTargetString( szBuffer, iClient, iTargets, sizeof( iTargets ), COMMAND_FILTER_CONNECTED|COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_IMMUNITY, szTargetName, sizeof( szTargetName ), bTargetNameML ) ) <= 0 )
		{
			ReplyToTargetError( iClient, nTargets );
			return Plugin_Handled;
		}
	}
	else if( nArgs == 4 )
	{
		for( int i = 0; i < 3; i++ )
		{
			GetCmdArg( i + 1, szBuffer, sizeof( szBuffer ) );
			StringToFloatEx( szBuffer, vecTarget[i] );
		}
		bOverrideCoords = true;
		nTargets = 1;
	}
	else if( iClient == 0 )
	{
		ReplyToCommand( iClient, "%sUsage: sm_spawni <weapon|item> <targets|x y z>", PLUGIN_MSG_PREFIX );
		return Plugin_Handled;
	}
	else if( nArgs == 1 )
	{
		iTargets[0] = iClient;
		nTargets = 1;
	}
	else
	{
		ReplyToCommand( iClient, "%sUsage: sm_spawni <weapon|item> [targets|x y z]", PLUGIN_MSG_PREFIX );
		return Plugin_Handled;
	}
	
	GetCmdArg( 1, szBuffer, sizeof( szBuffer ) );
	char sModel[256];
	switch( FindItemEx( iClient, szBuffer, szClassname, sizeof( szClassname ), szItemName[0], sizeof( szItemName[] ), szItemName[1], sizeof( szItemName[] ), bItemNameIsML, iMaxAmmo[0], iMaxAmmo[1],
		sModel, sizeof( sModel ) ) )
	{
		case 1: {}
		case FindItem_FoundNothing:
		{
			ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP No Matching" );
			return Plugin_Handled;
		}
		case FindItem_InvalidArg:
		{
			ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP Invalid Item Argument", szBuffer );
			return Plugin_Handled;
		}
		case FindItem_NoAccess:
		{
			ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP No Access" );
			return Plugin_Handled;
		}
		case FindItem_NotAvaliable:
		{
			ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP Cannot Spawn" );
			return Plugin_Handled;
		}
		default:
		{
			ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP Multiple Items" );
			return Plugin_Handled;
		}
	}
	
	int iEntity;
	
	for( int c = 0; c < nTargets; c++ )
	{
		if(strncmp(szClassname, "item_inventory_box", 18, false) == 0)
		{
			iEntity = CreateEntityByName( "item_inventory_box" );
			if( iEntity <= MaxClients )
			{
				ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP Invalid Item Entity", szClassname );
				return Plugin_Handled;
			}

			DispatchKeyValue(iEntity, "spawnsolid", "0");
			DispatchKeyValue(iEntity, "model", sModel);
		}
		else
		{
			iEntity = CreateEntityByName( szClassname );
			if( iEntity <= MaxClients )
			{
				ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP Invalid Item Entity", szClassname );
				return Plugin_Handled;
			}
		}

		DispatchSpawn( iEntity );
		if( !bOverrideCoords )
		{
			GetClientEyePosition( iTargets[c], vecTarget );
			GetClientEyeAngles( iTargets[c], vecEyeAngles );
			TeleportEntity( iEntity, vecTarget, vecEyeAngles, NULL_VECTOR );
		}
		else
		{
			TeleportEntity( iEntity, vecTarget, NULL_VECTOR, NULL_VECTOR );
		}
		ActivateEntity( iEntity );
		//AcceptEntityInput( iEntity, "Use", iTargets[c], iTargets[c] );
		
		/*if( bOverrideCoords )
		{
			if( !bSilentAdmin )
				ShowActivity2( iClient, PLUGIN_MSG_PREFIX, "%t", bItemNameIsML ? "NMP Activity Placed T" : "NMP Activity Placed", szItemName[1] );
			LogAction( iClient, -1, "placed '%s' @ %.2f %.2f %.2f", szClassname, vecTarget[0], vecTarget[1], vecTarget[2] );
		}
		else
		{
			if( !bSilentAdmin && !bTargetNameML )
				ShowActivity2( iClient, PLUGIN_MSG_PREFIX, "%t", bItemNameIsML ? "NMP Activity Spawn 2 T" : "NMP Activity Spawn 2", szItemName[1], iTargets[c] );
			LogAction( iClient, iTargets[c], "spawned '%s'", szClassname );
		}*/
	}
	
	if( !bOverrideCoords && !bSilentAdmin && bTargetNameML )
		ShowActivity2( iClient, PLUGIN_MSG_PREFIX, "%t", bItemNameIsML ? "NMP Activity Spawn T" : "NMP Activity Spawn", szItemName[1], szTargetName );
	
	return Plugin_Handled;
}

Action Command_ReloadConfigs( int iClient, int nArgs )
{
	if( ReadItemsData() )
		ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP Data Reloaded" );
	else
		ReplyToCommand( iClient, "%s%t", PLUGIN_MSG_PREFIX, "NMP Data Not Reloaded" );
	return Plugin_Handled;
}

Action Command_Scan( int iClient, int nArgs )
{
	if( iClient <= 0 || iClient > MaxClients || !IsClientInGame( iClient ) )
	{
		ReplyToCommand( iClient, "You must be in-game to execute this command." );
		return Plugin_Handled;
	}
	
	if( !IsPlayerAlive( iClient ) )
	{
		ReplyToCommand( iClient, "You must be alive to execute this command." );
		return Plugin_Handled;
	}
	
	PrintToServer( "> %N executed sm_gw_scan:", iClient );
	
	int iCarriedWeight = GetEntProp( iClient, Prop_Send, "_carriedWeight" );
	PrintToConsole( iClient, ">> _carriedWeight: %d", iCarriedWeight );
	PrintToServer( ">> _carriedWeight: %d", iCarriedWeight );
	
	int iEntity; char szClassname[21];
	for( int i = 0; i < 48; i++ )
	{
		iEntity = GetEntPropEnt( iClient, Prop_Send, "m_hMyWeapons", i );
		if( IsValidEdict( iEntity ) )
		{
			GetEntityClassname( iEntity, szClassname, sizeof( szClassname ) );
			PrintToConsole( iClient, ">>>> m_hMyWeapons (%03d): %05d %s", i, iEntity, szClassname, GetEntProp( iEntity, Prop_Send, "m_iPrimaryAmmoType" ) );
			PrintToServer( ">>>> m_hMyWeapons (%03d): %05d %s (ammotype:%d)", i, iEntity, szClassname, GetEntProp( iEntity, Prop_Send, "m_iPrimaryAmmoType" ) );
		}
	}
	
	for( int iAmmo, i = 0; i < 32; i++ )
	{
		iAmmo = GetEntProp( iClient, Prop_Send, "m_iAmmo", _, i );
		if( iAmmo )
		{
			PrintToConsole( iClient, ">>>> m_iAmmo (%03d): %d", i, iAmmo );
			PrintToServer( ">>>> m_iAmmo (%03d): %d", i, iAmmo );
		}
	}
	
	return Plugin_Handled;
}


public void OnAdminMenuReady(Handle hTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(hTopMenu);

	if( hLastTopMenu == topmenu )
		return;

	hLastTopMenu = topmenu;
	
#if defined ADMINMENU_NEW_CATEGORY
	TopMenuObject menu = AddToTopMenu( hLastTopMenu, "nmp_gw_cmds", TopMenuObject_Category, Handle_MenuCategory, INVALID_TOPMENUOBJECT );
#else
	TopMenuObject menu = FindTopMenuCategory( hLastTopMenu, ADMINMENU_PLAYERCOMMANDS );
#endif
	if( menu == INVALID_TOPMENUOBJECT )
		return;
	
	AddToTopMenu( hLastTopMenu, "nmp_gw_give", TopMenuObject_Item, Handle_MenuGiveItem, menu, "sm_give", ADMFLAG_ROOT );
	AddToTopMenu( hLastTopMenu, "nmp_gw_spawni", TopMenuObject_Item, Handle_MenuSpawnItem, menu, "sm_spawni", ADMFLAG_ROOT );
}

#if defined ADMINMENU_NEW_CATEGORY
void Handle_MenuCategory(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch( action )
	{
		case TopMenuAction_DisplayOption:
			Format( buffer, maxlength, "%T", "NMP AM Category", param );
		case TopMenuAction_DisplayTitle:
			Format( buffer, maxlength, "%T", "NMP AM Action", param );
	}
}
#endif
void Handle_MenuGiveItem(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch( action )
	{
		case TopMenuAction_DisplayOption:
			Format( buffer, maxlength, "%T", "NMP AM Give Item", param );
		case TopMenuAction_SelectOption:
		{
			g_iSelectMenuPos[param] = 0;
			ShowAdminMenu( param, ADMINMENU_GIVE_ITEM );
		}
	}
}
void Handle_MenuSpawnItem(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	switch( action )
	{
		case TopMenuAction_DisplayOption:
			Format( buffer, maxlength, "%T", "NMP AM Spawn Item", param );
		case TopMenuAction_SelectOption:
		{
			g_iSelectMenuPos[param] = 0;
			ShowAdminMenu( param, ADMINMENU_SPAWN_ITEM );
		}
	}
}

void ShowAdminMenu( int iClient, int nType )
{
	if( !( 0 < iClient <= MaxClients ) || !IsClientInGame( iClient ) )
		return;
	
	CancelClientMenu( iClient );
	
	Menu menu;
	switch( nType )
	{
		case ADMINMENU_GIVE_ITEM:		menu = CreateMenu( Menu_GiveItem );
		case ADMINMENU_GIVE_TARGET:		menu = CreateMenu( Menu_GiveTarget );
		case ADMINMENU_SPAWN_ITEM:		menu = CreateMenu( Menu_SpawnItem );
		case ADMINMENU_SPAWN_TARGET:	menu = CreateMenu( Menu_SpawnTarget );
		default:						return;
	}
	
	char szBuffer[3][121];
	if( nType == ADMINMENU_GIVE_TARGET || nType == ADMINMENU_SPAWN_TARGET )
	{
		Format( szBuffer[0], sizeof( szBuffer[] ), "%T", "NMP AM Select Target", iClient );
		SetMenuTitle( menu, szBuffer[0] );
		
		Format( szBuffer[0], sizeof( szBuffer[] ), "%T", "all alive players", iClient );
		AddMenuItem( menu, "@alive", szBuffer[0] );
		
		if( IsPlayerAlive( iClient ) )
		{
			Format( szBuffer[0], sizeof( szBuffer[] ), "%N (%d)", iClient, GetClientUserId( iClient ) );
			AddMenuItem( menu, "@me", szBuffer[0] );
		}
		
		for( int i = 1; i <= MaxClients; i++ )
			if( i != iClient && IsClientInGame( i ) && IsPlayerAlive( i ) )
			{
				Format( szBuffer[0], sizeof( szBuffer[] ), "#%d", GetClientUserId( i ) );
				Format( szBuffer[1], sizeof( szBuffer[] ), "%N (%d)", i, GetClientUserId( i ) );
				
				AddMenuItem( menu, szBuffer[0], szBuffer[1] );
			}

		SetMenuExitButton( menu, true );
		SetMenuExitBackButton( menu, true );
		DisplayMenu( menu, iClient, MENU_TIME_FOREVER );
	}
	else
	{
		Format( szBuffer[0], sizeof( szBuffer[] ), "%T", "NMP AM Select Item", iClient );
		SetMenuTitle( menu, szBuffer[0] );
		
		if( hItemsData != null )
		{
			KeyValues hItems = CreateKeyValues( "items" );
			KvRewind( hItemsData );
			KvCopySubkeys( hItemsData, hItems );
			if( KvJumpToKey( hItems, "items" ) && KvGotoFirstSubKey( hItems ) )
				do
				{
					KvGetString( hItems, "classname", szBuffer[2], sizeof( szBuffer[] ) );
					if( szBuffer[2][0] == '\0' )
						continue;
					
					KvGetString( hItems, "type", szBuffer[1], sizeof( szBuffer[] ) );
					if( szBuffer[1][0] != '\0' )
					{
						GetTypeMLString( szBuffer[1], szBuffer[1], sizeof( szBuffer[] ) );
						Format( szBuffer[1], sizeof( szBuffer[] ), "%T", szBuffer[1], iClient );
					}
					else
						strcopy( szBuffer[1], sizeof( szBuffer[] ), "unknown" );
					
					KvGetString( hItems, "name_short", szBuffer[0], sizeof( szBuffer[] ) );
					if( szBuffer[0][0] == '\0' )
					{
						KvGetString( hItems, "name_ml", szBuffer[0], sizeof( szBuffer[] ) );
						if( szBuffer[0][0] == '\0' )
							Format( szBuffer[0], sizeof( szBuffer[] ), "Weapon_%s_short", szBuffer[2] );
						Format( szBuffer[1], sizeof( szBuffer[] ), "%T [%s]", szBuffer[0], iClient, szBuffer[1], iClient );
					}
					else
						Format( szBuffer[1], sizeof( szBuffer[] ), "%s [%s]", szBuffer[0], szBuffer[1], iClient );
					
					AddMenuItem( menu, szBuffer[2], szBuffer[1] );
				}
				while( KvGotoNextKey( hItems ) );
			CloseHandle( hItems );
		}

		SetMenuExitButton( menu, true );
		SetMenuExitBackButton( menu, true );
		DisplayMenuAtItem( menu, iClient, g_iSelectMenuPos[iClient], MENU_TIME_FOREVER );
	}
}

int Menu_GiveItem(Menu menu, MenuAction action, int param1, int param2)
{
	switch( action )
	{
		case MenuAction_End:
			CloseHandle( menu );
		case MenuAction_Cancel:
			if( param2 == MenuCancel_ExitBack && hLastTopMenu != null )
				DisplayTopMenu( hLastTopMenu, param1, TopMenuPosition_LastCategory );
		case MenuAction_Select:
		{
			g_iSelectMenuPos[param1] = GetMenuSelectionPosition();
			GetMenuItem( menu, param2, szSelectedItem[param1], sizeof( szSelectedItem[] ) );
			ShowAdminMenu( param1, ADMINMENU_GIVE_TARGET );
		}
	}

	return 0;
}

int Menu_GiveTarget(Menu menu, MenuAction action, int param1, int param2)
{
	switch( action )
	{
		case MenuAction_End:
			CloseHandle( menu );
		case MenuAction_Cancel:
			if( param2 == MenuCancel_ExitBack && hLastTopMenu != null )
				ShowAdminMenu( param1, ADMINMENU_GIVE_ITEM );
		case MenuAction_Select:
		{
			char szBuffer[48];
			GetMenuItem( menu, param2, szBuffer, sizeof( szBuffer ) );
			FakeClientCommand( param1, "sm_give %s %s", szBuffer, szSelectedItem[param1] );
			//ShowAdminMenu( param1, ADMINMENU_GIVE_TARGET );
			ShowAdminMenu( param1, ADMINMENU_GIVE_ITEM );
		}
	}

	return 0;
}

int Menu_SpawnItem(Menu menu, MenuAction action, int param1, int param2)
{
	switch( action )
	{
		case MenuAction_End:
			CloseHandle( menu );
		case MenuAction_Cancel:
			if( param2 == MenuCancel_ExitBack && hLastTopMenu != null )
				DisplayTopMenu( hLastTopMenu, param1, TopMenuPosition_LastCategory );
		case MenuAction_Select:
		{
			g_iSelectMenuPos[param1] = GetMenuSelectionPosition();
			GetMenuItem( menu, param2, szSelectedItem[param1], sizeof( szSelectedItem[] ) );
			ShowAdminMenu( param1, ADMINMENU_SPAWN_TARGET );
		}
	}

	return 0;
}

int Menu_SpawnTarget(Menu menu, MenuAction action, int param1, int param2)
{
	switch( action )
	{
		case MenuAction_End:
			CloseHandle( menu );
		case MenuAction_Cancel:
			if( param2 == MenuCancel_ExitBack && hLastTopMenu != null )
				ShowAdminMenu( param1, ADMINMENU_SPAWN_ITEM );
		case MenuAction_Select:
		{
			char szBuffer[48];
			GetMenuItem( menu, param2, szBuffer, sizeof( szBuffer ) );
			FakeClientCommand( param1, "sm_spawni %s %s", szSelectedItem[param1], szBuffer );
			//ShowAdminMenu( param1, ADMINMENU_SPAWN_TARGET );
			ShowAdminMenu( param1, ADMINMENU_SPAWN_ITEM );
		}
	}

	return 0;
}

bool ReadItemsData( )
{
	delete hItemsData;
	
	char szFile[PLATFORM_MAX_PATH];
	BuildPath( Path_SM, szFile, sizeof( szFile ), PATH_ITEMS_DATA );
	if( !FileExists( szFile ) )
	{
		LogError( "Failed to open file '%s'!", PATH_ITEMS_DATA );
		return false;
	}
	
	hItemsData = CreateKeyValues( "items_data" );
	if( !FileToKeyValues( hItemsData, szFile ) )
	{
		delete hItemsData;
		LogError( "Failed to parse file '%s'!", PATH_ITEMS_DATA );
		return false;
	}
	
	return true;
}

void GetTypeMLString( const char[] szType, char[] szOutput, int iOutputLength )
{
	if( hItemsData != null )
	{
		KeyValues hTypes = CreateKeyValues( "types" );
		KvRewind( hItemsData );
		KvCopySubkeys( hItemsData, hTypes );
		if( KvJumpToKey( hTypes, "types" ) && KvJumpToKey( hTypes, szType ) )
			KvGetString( hTypes, "name", szOutput, iOutputLength );
		CloseHandle( hTypes );
	}
	if( szOutput[0] == '\0' )
		strcopy( szOutput, iOutputLength, szType );
}

int FindItemEx( int iAdmin = 0, const char[] szSearch, char[] szClassname = "", int iClassnameLen = 0, char[] szItemName = "", int iItemNameLen = 0, char[] szItemNameShort = "", int iItemNameShortLen = 0, bool &bItemNameIsML = false, int &iMaxAmmo1 = 0, int &iMaxAmmo2 = 0,
	 char[] sModel = "", int iModelLen = 0)
{
	char szBuffer[21];
	char szItemClass[21];
	int nFoundItems;
	bool bNotAvaliable = false;
	bool bNoAccess = false;
	
	bItemNameIsML = false;
	
	if( hItemsData != null )
	{
		KvRewind( hItemsData );
		if( KvJumpToKey( hItemsData, "items" ) && KvGotoFirstSubKey( hItemsData ) )
		{
			do
			{
				KvGetString( hItemsData, "classname", szItemClass, sizeof( szItemClass ) );
				if( !strlen( szItemClass ) || strcmp( szItemClass, szSearch, false ) != 0 )
				{
					continue;
				}
				else
				{
					strcopy( szClassname, iClassnameLen, szItemClass );
					
					iMaxAmmo1 = KvGetNum( hItemsData, "max_ammo_prim", 0 );
					iMaxAmmo2 = KvGetNum( hItemsData, "max_ammo_sec", 0 );
					
					KvGetString( hItemsData, "name_ml", szItemName, iItemNameLen, "" );
					if( !strlen( szItemName ) )
					{
						KvGetString( hItemsData, "name", szItemName, iItemNameLen, "" );
						if( !strlen( szItemName ) )
						{
							bItemNameIsML = true;
							Format( szItemName, iItemNameLen, "Weapon_%s", szItemClass );
						}
					}
					else
						bItemNameIsML = true;
					
					KvGetString( hItemsData, "name_short", szItemNameShort, iItemNameShortLen, "" );
					if( !strlen( szItemNameShort ) )
						Format( szItemNameShort, iItemNameShortLen, "%s_short", szItemName );

					hItemsData.GetString("model", sModel, iModelLen, "" );
					
					if( 0 < iAdmin <= MaxClients && IsClientInGame( iAdmin ) )
					{
						KvGetString( hItemsData, "type", szBuffer, sizeof( szBuffer ), "other" );
						Format( szBuffer, sizeof( szBuffer ), "sm_give_type_%s", szBuffer );
						if( !CheckCommandAccess( iAdmin, szBuffer, ADMFLAG_ROOT, true ) )
						{
							bNoAccess = true;
							break;
						}
						
						KvGetString( hItemsData, "category", szBuffer, sizeof( szBuffer ), "other" );
						Format( szBuffer, sizeof( szBuffer ), "sm_give_category_%s", szBuffer );
						if( !CheckCommandAccess( iAdmin, szBuffer, ADMFLAG_ROOT, true ) )
						{
							bNoAccess = true;
							break;
						}
					}
					
					nFoundItems=1;
					break;
				}
			}
			while( hItemsData.GotoNextKey() );
		}
	}
	else
	{
		LogMessage( "Items data isn't loaded!" );
		
		if( strlen( szSearch ) < 4 || !(
			StrContains( szSearch, "fa_", true ) == 0
			|| StrContains( szSearch, "me_", true ) == 0
			|| StrContains( szSearch, "item_", true ) == 0
			|| StrContains( szSearch, "tool_", true ) == 0
		) )
			return FindItem_InvalidArg;
		
		strcopy( szClassname, iClassnameLen, szSearch );
		
		nFoundItems=1;
	}
	
	if( nFoundItems == 0 )
	{
		if( bNotAvaliable )
			return FindItem_NotAvaliable;
		else if( bNoAccess )
			return FindItem_NoAccess;
		else
			return FindItem_FoundNothing;
	}
	
	return nFoundItems;
}