#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <basecomm>
#include <smlib>

public Plugin myinfo =
{
	name = "No Team Chat",
	author = "bullet28, HarryPotter",
	description = "Redirecting all 'say_team' messages to 'say', print team chat message to all clients on the server",
	version = "1.0h-2025/12/2",
	url = "https://forums.alliedmods.net/showthread.php?p=2691314"
}


ConVar cvarIgnoreList;
char ignoreList[32][8];

public void OnPluginStart() {

	cvarIgnoreList = CreateConVar("noteamsay_ignorelist", "!,/,@", "Messages starting with this will be ignored, separate by , symbol", FCVAR_NONE);
	
	GetCvars();
	cvarIgnoreList.AddChangeHook(OnConVarChange);
	
	AutoExecConfig(true, "lfd_noTeamSay");
}

public void OnConVarChange(ConVar convar, char[] oldValue, char[] newValue) {
	GetCvars();
}

void GetCvars()
{
	char buffer[256];
	cvarIgnoreList.GetString(buffer, sizeof buffer);
	for (int i = 0; i < sizeof ignoreList; i++) ignoreList[i] = "";
	ExplodeString(buffer, ",", ignoreList, sizeof ignoreList, sizeof ignoreList[]);
}

/*public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs) {
	
	if (client <= 0)
		return Plugin_Continue;
	
	if (strcmp(command, "say_team", false) != 0)
		return Plugin_Continue;

	if (BaseComm_IsClientGagged(client) == true) //this client has been gagged
		return Plugin_Continue;	
		
	for (int i = 0; i < sizeof ignoreList; i++) {
		if ( ignoreList[i][0] != EOS && strncmp(sArgs, ignoreList[i], strlen(ignoreList[i])) == 0 ) {
			return Plugin_Continue;
		}
	}

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i)) {
			SayText2(i, client, sArgs);
		}
	}

	return Plugin_Continue;
}

void SayText2(int client, int sender, const char[] msg) {

	static char name[MAX_NAME_LENGTH];
	GetClientName(sender, name, sizeof(name));

	Handle hMessage = StartMessageOne("SayText2", client, USERMSG_RELIABLE);
	if(hMessage != null) 
	{
		BfWriteByte(hMessage, sender);
		BfWriteByte(hMessage, true);
		BfWriteString(hMessage, sAllMsg);
		BfWriteString(hMessage, name);
		BfWriteString(hMessage, msg);
		BfWriteByte(hMessage, true);
		EndMessage();
	}
}
*/

public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs) {
	
	if (client <= 0)
		return;
	
	if (strcmp(command, "say_team", false) != 0)
		return;

	if (BaseComm_IsClientGagged(client) == true) //this client has been gagged
		return;	
		
	for (int i = 0; i < sizeof ignoreList; i++) {
		if ( ignoreList[i][0] != EOS && strncmp(sArgs, ignoreList[i], strlen(ignoreList[i])) == 0 ) {
			return;
		}
	}

	DataPack hPack = new DataPack();
	hPack.WriteCell(GetClientUserId(client));
	hPack.WriteCell(GetClientTeam(client));
	hPack.WriteString(sArgs);
	RequestFrame(OnNextFrame_OnClientSayCommand_Post, hPack);

	return;
}

void OnNextFrame_OnClientSayCommand_Post(DataPack hPack)
{
	hPack.Reset();
	int client = GetClientOfUserId(hPack.ReadCell());
	int team = hPack.ReadCell();
	char sArgs[256]; hPack.ReadString(sArgs, sizeof sArgs);
	delete hPack;

	if(!client || !IsClientInGame(client)) return;

	char buffer[256];
	FormatEx(buffer, sizeof(buffer), "(NO TEAMCHAT) %N :  %s", client, sArgs);

	for (int i = 1; i <= MaxClients; i++) {
		if (i != client && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != team) {
			Client_PrintToChat(i, true, buffer);
		}
	}

	//Client_PrintToChat(client, true, buffer);
}
