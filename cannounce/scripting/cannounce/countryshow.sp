/*****************************************************************


			G L O B A L   V A R S


*****************************************************************/
ConVar g_CvarShowConnect = null;
ConVar g_CvarShowDisconnect = null;
ConVar g_CvarShowEnhancedToAdmins = null;
Handle hKVCountryShow = null;


/*****************************************************************


			F O R W A R D   P U B L I C S


*****************************************************************/
void SetupCountryShow()
{
	g_CvarShowConnect = CreateConVar("sm_ca_showenhanced", "1", "displays enhanced message when player connects");
	g_CvarShowDisconnect = CreateConVar("sm_ca_showenhanceddisc", "1", "displays enhanced message when player disconnects");
	g_CvarShowEnhancedToAdmins = CreateConVar("sm_ca_showenhancedadmins", "1", "displays a different enhanced message to admin players (ADMFLAG_GENERIC)");
	
	//prepare kv for countryshow
	hKVCountryShow = CreateKeyValues("CountryShow");
	
	if(!FileToKeyValues(hKVCountryShow, g_filesettings))
	{
		KeyValuesToFile(hKVCountryShow, g_filesettings);
	}
	
	SetupDefaultMessages();
}

void OnPostAdminCheck_CountryShow(int client)
{
	char rawmsg[301];
	char rawadmmsg[301];

	//if enabled, show message
	if( g_CvarShowConnect.BoolValue )
	{
		KvRewind(hKVCountryShow);
		
		//get message admins will see (if sm_ca_showenhancedadmins)
		if( KvJumpToKey(hKVCountryShow, "messages_admin", false) )
		{
			KvGetString(hKVCountryShow, "playerjoin", rawadmmsg, sizeof(rawadmmsg), "");
			Format(rawadmmsg, sizeof(rawadmmsg), "%c%s", 1, rawadmmsg);
			KvRewind(hKVCountryShow);
		}
		
		//get message all players will see
		if( KvJumpToKey(hKVCountryShow, "messages", false) )
		{
			KvGetString(hKVCountryShow, "playerjoin", rawmsg, sizeof(rawmsg), "");
			Format(rawmsg, sizeof(rawmsg), "%c%s", 1, rawmsg);
			KvRewind(hKVCountryShow);
		}
		
		//if sm_ca_showenhancedadmins - show diff messages to admins
		if( g_CvarShowEnhancedToAdmins.BoolValue )
		{
			PrintFormattedMessageToAdmins( rawadmmsg, client, true );
			PrintFormattedMsgToNonAdmins( rawmsg, client, true );
			PrintMsgToSourceTV( client, true );
		}
		else
		{
			PrintFormattedMessageToAll( rawmsg, client, true );
			PrintMsgToSourceTV( client, true );
		}
	}	
}

void OnPluginEnd_CountryShow()
{		
	CloseHandle(hKVCountryShow);
}


/****************************************************************


			C A L L B A C K   F U N C T I O N S


****************************************************************/
void event_PlayerDisc_CountryShow(Event event)
{
	char rawmsg[301];
	char rawadmmsg[301];
	char reason[65];
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	//if enabled, show message
	if( g_CvarShowDisconnect.BoolValue )
	{
		GetEventString(event, "reason", reason, sizeof(reason));

		KvRewind(hKVCountryShow);
		
		//get message admins will see (if sm_ca_showenhancedadmins)
		if( KvJumpToKey(hKVCountryShow, "messages_admin", false) )
		{
			KvGetString(hKVCountryShow, "playerdisc", rawadmmsg, sizeof(rawadmmsg), "");
			Format(rawadmmsg, sizeof(rawadmmsg), "%c%s", 1, rawadmmsg);
			KvRewind(hKVCountryShow);
			
			//first replace disconnect reason if applicable
			if (StrContains(rawadmmsg, "{DISC_REASON}") != -1 ) 
			{
				ReplaceString(rawadmmsg, sizeof(rawadmmsg), "{DISC_REASON}", reason);
				
				//strip carriage returns, replace with space
				ReplaceString(rawadmmsg, sizeof(rawadmmsg), "\n", " ");
				
			}
		}
		
		//get message all players will see
		if( KvJumpToKey(hKVCountryShow, "messages", false) )
		{
			KvGetString(hKVCountryShow, "playerdisc", rawmsg, sizeof(rawmsg), "");
			Format(rawmsg, sizeof(rawmsg), "%c%s", 1, rawmsg);
			KvRewind(hKVCountryShow);
			
			//first replace disconnect reason if applicable
			if (StrContains(rawmsg, "{DISC_REASON}") != -1 ) 
			{
				ReplaceString(rawmsg, sizeof(rawmsg), "{DISC_REASON}", reason);
				
				//strip carriage returns, replace with space
				ReplaceString(rawmsg, sizeof(rawmsg), "\n", " ");
			}
		}
		
		//if sm_ca_showenhancedadmins - show diff messages to admins
		if( g_CvarShowEnhancedToAdmins.BoolValue )
		{
			PrintFormattedMessageToAdmins( rawadmmsg, client, false );
			PrintFormattedMsgToNonAdmins( rawmsg, client, false );
			PrintMsgToSourceTV( client, false );
		}
		else
		{
			PrintFormattedMessageToAll( rawmsg, client, false );
			PrintMsgToSourceTV( client, false );
		}
		
		KvRewind(hKVCountryShow);
	}
}

/*****************************************************************


			P L U G I N   F U N C T I O N S


*****************************************************************/
void SetupDefaultMessages()
{
	if(!KvJumpToKey(hKVCountryShow, "messages"))
	{				
		KvJumpToKey(hKVCountryShow, "messages", true);
		KvSetString(hKVCountryShow, "playerjoin", "{default}[{olive}TS{default}] {blue}Player {green}{PLAYERNAME} {blue}connected{default}. ({green}{PLAYERCOUNTRY}{default})");
		KvSetString(hKVCountryShow, "playerdisc", "{default}[{olive}TS{default}] {red}Player {green}{PLAYERNAME} {red}disconnected{default}. ({green}{DISC_REASON}{default})");

		KvRewind(hKVCountryShow);			
		KeyValuesToFile(hKVCountryShow, g_filesettings);		
	}
	
	KvRewind(hKVCountryShow);
	
	if(!KvJumpToKey(hKVCountryShow, "messages_admin"))
	{				
		KvJumpToKey(hKVCountryShow, "messages_admin", true);
		KvSetString(hKVCountryShow, "playerjoin", "{default}[{olive}TS{default}] {blue}Player {green}{PLAYERNAME} {blue}connected{default}. ({green}{PLAYERCOUNTRY}, {PLAYERREGION}, {PLAYERCITY}{default}) IP: {green}{PLAYERIP}{default} {olive}<ID:{STEAMID}>");
		KvSetString(hKVCountryShow, "playerdisc", "{default}[{olive}TS{default}] {red}Player {green}{PLAYERNAME} {red}disconnected{default}. ({green}{DISC_REASON}{default}) IP: {green}{PLAYERIP}{default} {olive}<ID:{STEAMID}>");

		KvRewind(hKVCountryShow);			
		KeyValuesToFile(hKVCountryShow, g_filesettings);		
	}

	KvRewind(hKVCountryShow);
}