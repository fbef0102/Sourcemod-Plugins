/**
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 */


#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <geoip>
#include <adminmenu>
#include <multicolors>

#define VERSION "2.3-2025/7/13"

/*****************************************************************


			G L O B A L   V A R S


*****************************************************************/
Handle hTopMenu = null;
char g_filesettings[128];

ConVar g_hCvarDisplayAdmin, g_hCvarDisplaySelfCon, g_hCvarDisplayDiscInGame;
bool g_bCvarDisplayAdmin, g_bCvarDisplaySelfCon, g_bCvarDisplayDiscInGame;
/*****************************************************************


			L I B R A R Y   I N C L U D E S


*****************************************************************/
#include "cannounce/countryshow.sp"
#include "cannounce/joinmsg.sp"
#include "cannounce/geolist.sp"
#include "cannounce/suppress.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	if( !IsDedicatedServer() )
	{
		strcopy(error, err_max, "Get a dedicated server. This plugin does not work on Listen servers.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success; 
}


/*****************************************************************


			P L U G I N   I N F O


*****************************************************************/
public Plugin myinfo =
{
	name = "Connect Announce",
	author = "Arg!, modify by harry",
	description = "Replacement of default player connection message, allows for custom connection messages",
	version = VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=77306"
};



/*****************************************************************


			F O R W A R D   P U B L I C S


*****************************************************************/
public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("cannounce.phrases");
	
	CreateConVar("sm_cannounce_version", VERSION, "Connect announce replacement", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarDisplayAdmin 		= CreateConVar("sm_ca_display_admin", 		"1", "If 1, Display if player is admin on connect/disconnect message (allows the {PLAYERTYPE} placeholder)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarDisplaySelfCon 		= CreateConVar("sm_ca_display_self_con", 	"1", "0=The connected players will not see their own join message\n1=The connected players can see their own join message", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarDisplayDiscInGame 	= CreateConVar("sm_ca_display_disc_ingame", "0", "If 1, Only display disconnect message after player is fully in server", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	AutoExecConfig(true,                   "cannounce");

	GetCvars();
	g_hCvarDisplayAdmin.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDisplaySelfCon.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDisplayDiscInGame.AddChangeHook(ConVarChanged_Cvars);

	BuildPath(Path_SM, g_filesettings, 128, "data/cannounce_settings.txt");
	
	//event hooks
	HookEvent("player_disconnect", event_PlayerDisconnect, EventHookMode_Pre);
	
	
	//country show
	SetupCountryShow();
	
	//custom join msg
	SetupJoinMsg();
	
	//geographical player list
	SetupGeoList();
	
	//suppress standard connection message
	SetupSuppress();
	
	//Account for late loading
	TopMenu topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
	{
		OnAdminMenuReady(topmenu);
	}
}

// Cvars-------------------------------

void ConVarChanged_Cvars(ConVar hCvar, const char[] sOldVal, const char[] sNewVal)
{
	GetCvars();
}

void GetCvars()
{
	g_bCvarDisplayAdmin = g_hCvarDisplayAdmin.BoolValue;
	g_bCvarDisplaySelfCon = g_hCvarDisplaySelfCon.BoolValue;
	g_bCvarDisplayDiscInGame = g_hCvarDisplayDiscInGame.BoolValue;
}

public void OnMapStart()
{	
	OnMapStart_JoinMsg();
}

public void OnMapEnd()
{
	OnMapEnd_JoinMsg();
}

public void OnConfigsExecuted()
{
	OnConfigsExecuted_JoinMsg();
}

public void OnClientPostAdminCheck(client)
{
	if( !IsFakeClient(client) )
	{
		CreateTimer(5.0, Timer_OnClientPostAdminCheck, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

Action Timer_OnClientPostAdminCheck(Handle timer, int client)
{
	client = GetClientOfUserId(client);
	if(client && IsClientInGame(client))
	{
		OnPostAdminCheck_CountryShow(client);
		OnPostAdminCheck_Sound();
	}

	return Plugin_Continue;
}

public void OnPluginEnd()
{		
	OnPluginEnd_JoinMsg();
	
	OnPluginEnd_CountryShow();
}


public void OnAdminMenuReady(Handle topmenu)
{
	//Block us from being called twice
	if (topmenu == hTopMenu)
	{
		return;
	}
	
	//Save the Handle
	hTopMenu = topmenu;
	
	
	OnAdminMenuReady_JoinMsg();	
}


public void OnLibraryRemoved(const char[] name)
{
	//remove this menu handle if adminmenu plugin unloaded
	if (strcmp(name, "adminmenu") == 0)
	{
		hTopMenu = null;
	}
}

/****************************************************************


			C A L L B A C K   F U N C T I O N S


****************************************************************/
void event_PlayerDisconnect(Event event, char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if( client && !IsFakeClient(client) )
	{
		if(g_bCvarDisplayDiscInGame && !IsClientInGame(client)) return;

		event_PlayerDisc_CountryShow(event);
		OnClientDisconnect_Sound();
	}
	
	event_PlayerDisconnect_Suppress( event );
}


/*****************************************************************


			P L U G I N   F U N C T I O N S


*****************************************************************/
//Thanks to Darkthrone (https://forums.alliedmods.net/member.php?u=54636)
bool IsLanIP( char src[16] )
{
	char ip4[4][4];
	int ipnum;

	if(ExplodeString(src, ".", ip4, 4, 4) == 4)
	{
		ipnum = StringToInt(ip4[0])*65536 + StringToInt(ip4[1])*256 + StringToInt(ip4[2]);
		
		if((ipnum >= 655360 && ipnum < 655360+65535) || (ipnum >= 11276288 && ipnum < 11276288+4095) || (ipnum >= 12625920 && ipnum < 12625920+255))
		{
			return true;
		}
	}

	return false;
}

void PrintFormattedMessageToAll( char rawmsg[301], int client, bool bConnect = true )
{
	char message[301];
	
	GetFormattedMessage( rawmsg, client, message, sizeof(message) );
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!g_bCvarDisplaySelfCon && bConnect && i == client) continue;
		if( !IsClientInGame(i) ) continue;
		if( IsFakeClient(i) )
		{
			if(!IsClientSourceTV(i)) continue;
		}

		C_PrintToChat(i, "%s", message);
	}

	C_LogMessage(message);
}

void PrintFormattedMessageToAdmins(char rawmsg[301], int client, bool bConnect = true )
{
	char message[301];
	
	GetFormattedMessage( rawmsg, client, message, sizeof(message) );
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!g_bCvarDisplaySelfCon && bConnect && i == client) continue;
		if( !IsClientInGame(i) ) continue;
		if( IsFakeClient(i) )
		{
			if(!IsClientSourceTV(i)) continue;
		}
		else
		{
			if(!CheckCommandAccess( i, "", ADMFLAG_GENERIC, true )) continue;
		}

		C_PrintToChat(i, "%s", message);
	}

	C_LogMessage(message, "MsgToAdmins");
}

void PrintFormattedMsgToNonAdmins( char rawmsg[301], int client, bool bConnect = true )
{
	char message[301];
	
	GetFormattedMessage( rawmsg, client, message, sizeof(message) );
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!g_bCvarDisplaySelfCon && bConnect && i == client) continue;
		if( !IsClientInGame(i) ) continue;
		if( IsFakeClient(i) ) continue;
		if(CheckCommandAccess( i, "", ADMFLAG_GENERIC, true )) continue;

		C_PrintToChat(i, "%s", message);
	}
	//C_LogMessage(message, "MsgToNonAdmins");
}

void PrintMsgToSourceTV( int client, bool bConnect )
{
	char message[256];
	char steamid[32];
	GetClientAuthId(client, AuthId_Steam3, steamid, sizeof(steamid));
	if(bConnect)
	{
		FormatEx(message, sizeof(message), "[{green}SourceTV{default}] {lightgreen}%N, %s{default} connected", client, steamid);
	}
	else
	{
		FormatEx(message, sizeof(message), "[{green}SourceTV{default}] {lightgreen}%N, %s{default} disconnected", client, steamid);
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if( !IsClientInGame(i) ) continue;
		if( !IsFakeClient(i) ) continue;
		if( !IsClientSourceTV(i) ) continue;

		CPrintToChat(i, message);
	}
}

//GetFormattedMessage - based on code from the DJ Tsunami plugin Advertisements - http://forums.alliedmods.net/showthread.php?p=592536
void GetFormattedMessage( char rawmsg[301], int client,char[] outbuffer, int outbuffersize )
{
	char buffer[256];
	char ip[16];
	char city[45];
	char region[45];
	char country[45];
	char ccode[3];
	char ccode3[4];
	char sPlayerAdmin[32];
	char sPlayerPublic[32];
	bool bIsLanIp;
	
	AdminId aid;
	
	if( client > -1 )
	{
		GetClientIP(client, ip, sizeof(ip)); 
		
		//detect LAN ip
		bIsLanIp = IsLanIP( ip );
		
		if( !GeoipCode2(ip, ccode) )
		{
			if( bIsLanIp )
			{
				Format( ccode, sizeof(ccode), "%T", "LAN Country Short", LANG_SERVER );
			}
			else
			{
				Format( ccode, sizeof(ccode), "%T", "Unknown Country Short", LANG_SERVER );
			}
		}
		
		if( !GeoipCountry(ip, country, sizeof(country)) )
		{
			if( bIsLanIp )
			{
				Format( country, sizeof(country), "%T", "LAN Country Desc", LANG_SERVER );
			}
			else
			{
				Format( country, sizeof(country), "%T", "Unknown Country Desc", LANG_SERVER );
			}
		}

		if(!GeoipCity(ip, city, sizeof(city)))
		{
			if( bIsLanIp )
			{
				Format( city, sizeof(city), "%T", "LAN City Desc", LANG_SERVER );
			}
			else
			{
				Format( city, sizeof(city), "%T", "Unknown City Desc", LANG_SERVER );
			}
		}

		if(!GeoipRegion(ip, region, sizeof(region)))
		{
			if( bIsLanIp )
			{
				Format( region, sizeof(region), "%T", "LAN Region Desc", LANG_SERVER );
			}
			else
			{
				Format( region, sizeof(region), "%T", "Unknown Region Desc", LANG_SERVER );
			}
		}

		if(!GeoipCode3(ip, ccode3))
		{
			if( bIsLanIp )
			{
				Format( ccode3, sizeof(ccode3), "%T", "LAN Country Short 3", LANG_SERVER );
			}
			else
			{
				Format( ccode3, sizeof(ccode3), "%T", "Unknown Country Short 3", LANG_SERVER );
			}
		}
		
		// Fallback for unknown/empty location strings
		if( StrEqual( city, "" ) )
		{
			Format( city, sizeof(city), "%T", "Unknown City Desc", LANG_SERVER );
		}
		
		if( StrEqual( region, "" ) )
		{
			Format( region, sizeof(region), "%T", "Unknown Region Desc", LANG_SERVER );
		}
		
		if( StrEqual( country, "" ) )
		{
			Format( country, sizeof(country), "%T", "Unknown Country Desc", LANG_SERVER );
		}
		
		if( StrEqual( ccode, "" ) )
		{
			Format( ccode, sizeof(ccode), "%T", "Unknown Country Short", LANG_SERVER );
		}
		
		if( StrEqual( ccode3, "" ) )
		{
			Format( ccode3, sizeof(ccode3), "%T", "Unknown Country Short 3", LANG_SERVER );
		}
		
		// Add "The" in front of certain countries
		if( StrContains( country, "United", false ) != -1 || 
			StrContains( country, "Republic", false ) != -1 || 
			StrContains( country, "Federation", false ) != -1 || 
			StrContains( country, "Island", false ) != -1 || 
			StrContains( country, "Netherlands", false ) != -1 || 
			StrContains( country, "Isle", false ) != -1 || 
			StrContains( country, "Bahamas", false ) != -1 || 
			StrContains( country, "Maldives", false ) != -1 || 
			StrContains( country, "Philippines", false ) != -1 || 
			StrContains( country, "Vatican", false ) != -1 )
		{
			Format( country, sizeof(country), "The %s", country );
		}
		
		if (StrContains(rawmsg, "{PLAYERNAME}") != -1) 
		{
			GetClientName(client, buffer, sizeof(buffer));
			ReplaceString(rawmsg, sizeof(rawmsg), "{PLAYERNAME}", buffer);
		}

		if (StrContains(rawmsg, "{STEAMID}") != -1) 
		{
			GetClientAuthId(client, AuthId_Steam2, buffer, sizeof(buffer));
			ReplaceString(rawmsg, sizeof(rawmsg), "{STEAMID}", buffer);
		}
		
		if (StrContains(rawmsg, "{PLAYERCOUNTRY}") != -1 ) 
		{
			ReplaceString(rawmsg, sizeof(rawmsg), "{PLAYERCOUNTRY}", country);
		}
		
		if (StrContains(rawmsg, "{PLAYERCOUNTRYSHORT}") != -1 ) 
		{
			ReplaceString(rawmsg, sizeof(rawmsg), "{PLAYERCOUNTRYSHORT}", ccode);
		}
		
		if (StrContains(rawmsg, "{PLAYERCOUNTRYSHORT3}") != -1 ) 
		{
			ReplaceString(rawmsg, sizeof(rawmsg), "{PLAYERCOUNTRYSHORT3}", ccode3);
		}
		
		if (StrContains(rawmsg, "{PLAYERCITY}") != -1 ) 
		{
			ReplaceString(rawmsg, sizeof(rawmsg), "{PLAYERCITY}", city);
		}
		
		if (StrContains(rawmsg, "{PLAYERREGION}") != -1 ) 
		{
			ReplaceString(rawmsg, sizeof(rawmsg), "{PLAYERREGION}", region);
		}
		
		if (StrContains(rawmsg, "{PLAYERIP}") != -1 ) 
		{
			ReplaceString(rawmsg, sizeof(rawmsg), "{PLAYERIP}", ip);
		}
		
		if( StrContains(rawmsg, "{PLAYERTYPE}") != -1 && g_bCvarDisplayAdmin  )
		{
			aid = GetUserAdmin( client );
			
			if( GetAdminFlag( aid, Admin_Generic ) )
			{
				Format( sPlayerAdmin, sizeof(sPlayerAdmin), "%T", "CA Admin", LANG_SERVER );
				ReplaceString(rawmsg, sizeof(rawmsg), "{PLAYERTYPE}", sPlayerAdmin);
			}
			else
			{
				Format( sPlayerPublic, sizeof(sPlayerPublic), "%T", "CA Public", LANG_SERVER );
				ReplaceString(rawmsg, sizeof(rawmsg), "{PLAYERTYPE}", sPlayerPublic);
			}
		}
	}
	
	Format( outbuffer, outbuffersize, "%s", rawmsg );
}

void C_LogMessage( char rawmsg[301], char extramsg[32] = "")
{
	ReplaceString(rawmsg, sizeof(rawmsg), "{default}", "", false);
	ReplaceString(rawmsg, sizeof(rawmsg), "{blue}", "", false);
	ReplaceString(rawmsg, sizeof(rawmsg), "{red}", "", false);
	ReplaceString(rawmsg, sizeof(rawmsg), "{olive}", "", false);
	ReplaceString(rawmsg, sizeof(rawmsg), "{green}", "", false);
	ReplaceString(rawmsg, sizeof(rawmsg), "{lightgreen}", "", false);

	LogMessage( "%s%s",extramsg, rawmsg );
}