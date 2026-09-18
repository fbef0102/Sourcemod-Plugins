#include <sourcemod>
#include <sdktools>
#include <multicolors>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION	"1.1h-2026/9/18"
#define PLUGIN_NAME		"smd_advertisements"

public Plugin myinfo =
{
    name        = "Advertisements",
    author      = "Tsunami & HarryPotter",
    description = "Display advertisements at regular intervals, with translation support",
    version     = PLUGIN_VERSION,
    url         = "https://forums.alliedmods.net/showthread.php?t=155705"
};

bool bIsDedicated;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	bIsDedicated = IsDedicatedServer();

	return APLRes_Success; 
}


#define TRANSLATION_FILE		PLUGIN_NAME ... ".phrases"

#define CVAR_FLAGS                    FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION     FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY

ConVar g_hCvarEnable, g_hCvarType, g_hCvarInterval, g_hCvarSoundFile;
bool g_bCvarEnable;
int g_iCvarType;
float g_fCvarInterval;
char g_sCvarSoundFile[PLATFORM_MAX_PATH];

Handle 
    g_hTimer;

bool 
    g_bMapStarted;

int
    iAdIndex;

public void OnPluginStart()
{
    LoadTranslations(TRANSLATION_FILE);

    g_hCvarEnable       = CreateConVar( PLUGIN_NAME ... "_enable",      "1",                  "0=Plugin off, 1=Plugin on.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvarType         = CreateConVar( PLUGIN_NAME ... "_type",        "2",                  "How to display advertisement. 1=In center text, 2=In chat, 3=In Hint Box, 4=In Menu", FCVAR_NOTIFY, true, 1.0, true, 4.0);
    g_hCvarInterval     = CreateConVar( PLUGIN_NAME ... "_interval",    "30",                 "Amount of seconds between advertisements.", FCVAR_NOTIFY);
    g_hCvarSoundFile    = CreateConVar( PLUGIN_NAME ... "_soundfile",   "ui/beepclear.wav",   "Display advertisement sound file (relative to to sound/, empty=disable)", FCVAR_NOTIFY);
    CreateConVar(                       PLUGIN_NAME ... "_version",       PLUGIN_VERSION, PLUGIN_NAME ... " Plugin Version", CVAR_FLAGS_PLUGIN_VERSION);
    AutoExecConfig(true,                PLUGIN_NAME);

    GetCvars();
    g_hCvarEnable.AddChangeHook(ConVarChanged_RestartTimer);
    g_hCvarType.AddChangeHook(ConVarChanged_RestartTimer);
    g_hCvarInterval.AddChangeHook(ConVarChanged_RestartTimer);
    g_hCvarSoundFile.AddChangeHook(ConVarChanged_Cvars);
    
    iAdIndex = 1;
    g_hTimer = CreateTimer(g_fCvarInterval, Timer_DisplayAd, _, TIMER_REPEAT);
}

//Cvars-------------------------------

void ConVarChanged_RestartTimer(ConVar hCvar, const char[] sOldVal, const char[] sNewVal)
{
    GetCvars();

    RestartTimer();
}

void ConVarChanged_Cvars(ConVar hCvar, const char[] sOldVal, const char[] sNewVal)
{
	GetCvars();
}

void GetCvars()
{
    g_bCvarEnable = g_hCvarEnable.BoolValue;
    g_iCvarType = g_hCvarType.IntValue;
    g_fCvarInterval = g_hCvarInterval.FloatValue;
    g_hCvarSoundFile.GetString(g_sCvarSoundFile, sizeof(g_sCvarSoundFile));
    if (g_bMapStarted && strlen(g_sCvarSoundFile) > 0) PrecacheSound(g_sCvarSoundFile);
}

//Sourcemod API Forward-------------------------------

public void OnMapStart()
{	
    g_bMapStarted = true;
}

public void OnMapEnd()
{	
    g_bMapStarted = false;
}

public void OnConfigsExecuted()
{
    GetCvars();
    //RestartTimer();
}

// Frame & Timer

Action Timer_DisplayAd(Handle timer)
{
    if (!g_bCvarEnable) 
    {
        g_hTimer = null;
        return Plugin_Stop;
    }

    if(strlen(g_sCvarSoundFile) > 0) PlaySoundToAll(g_sCvarSoundFile);

    char sTran[4], sMessage[1024];
    FormatEx(sTran, sizeof sTran, "%d", iAdIndex);
    if(!TranslationPhraseExists(sTran))
    {
        iAdIndex = 1;
        FormatEx(sTran, sizeof sTran, "%d", iAdIndex);
    }
    if(!TranslationPhraseExists(sTran))
    {
        SetFailState("Unable to read the advertisement in smd_advertisements.phrases.txt");
        g_hTimer = null;
        return Plugin_Stop;
    }
    
    switch(g_iCvarType)
    {
        case 1:
        {
            for (int i = 1; i <= MaxClients; i++) 
            {
                if (IsClientInGame(i) && !IsFakeClient(i)) 
                {
                    FormatEx(sMessage, sizeof sMessage, "%T", sTran, i);
                    ProcessVariables(sMessage);
                    PrintCenterText(i, sMessage);
                }
            }
            
        }
        case 2:
        {
            for (int i = 1; i <= MaxClients; i++) 
            {
                if (IsClientInGame(i) && !IsFakeClient(i)) 
                {
                    FormatEx(sMessage, sizeof sMessage, "%T", sTran, i);
                    ProcessVariables(sMessage);
                    CPrintToChat(i, sMessage);
                }
            }
        }
        case 3:
        {
            for (int i = 1; i <= MaxClients; i++) 
            {
                if (IsClientInGame(i) && !IsFakeClient(i)) 
                {
                    FormatEx(sMessage, sizeof sMessage, "%T", sTran, i);
                    ProcessVariables(sMessage);
                    PrintHintText(i, sMessage);
                }
            }
        }
        case 4:
        {
            for (int i = 1; i <= MaxClients; i++) 
            {
                if (IsClientInGame(i) && !IsFakeClient(i)) 
                {
                    Panel menuPanel = new Panel();
                    FormatEx(sMessage, sizeof sMessage, "%T", sTran, i);
                    ProcessVariables(sMessage);
                    menuPanel.DrawText(sMessage);
                    menuPanel.Send(i, Handler_DoNothing, 10);
                    delete menuPanel;
                }
            }
        }
    }

    iAdIndex++;

    return Plugin_Continue;
}

// Meny
int Handler_DoNothing(Menu menu, MenuAction action, int param1, int param2) { return 0; }


// others

void PlaySoundToAll(const char[] sSoundName)
{
	if(bIsDedicated)
	{	
		EmitSoundToAll(sSoundName, _, SNDCHAN_AUTO, SNDLEVEL_CONVO, _, SNDVOL_NORMAL, _, _, _, _, _, _ );
	}
	else
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i)) continue;
			if(IsFakeClient(i)) continue;

			PlaySoundToClient(i, sSoundName);
		}
	}
}

void PlaySoundToClient(int client, const char[] sSoundName)
{
	EmitSoundToClient(client, sSoundName, _, SNDCHAN_AUTO, SNDLEVEL_CONVO, _, SNDVOL_NORMAL, _, _, _, _, _, _ );
}

void ProcessVariables(char sText[1024])
{
    char sBuffer[64];
    if (StrContains(sText, "{currentmap}", false) != -1) {
        GetCurrentMap(sBuffer, sizeof(sBuffer));
        ReplaceString(sText, sizeof(sText), "{currentmap}", sBuffer, false);
    }

    if (StrContains(sText, "{date}", false) != -1) {
        FormatTime(sBuffer, sizeof(sBuffer), "%m/%d/%Y");
        ReplaceString(sText, sizeof(sText), "{date}", sBuffer, false);
    }

    if (StrContains(sText, "{time}", false) != -1) {
        FormatTime(sBuffer, sizeof(sBuffer), "%I:%M:%S%p");
        ReplaceString(sText, sizeof(sText), "{time}", sBuffer, false);
    }

    if (StrContains(sText, "{time24}", false) != -1) {
        FormatTime(sBuffer, sizeof(sBuffer), "%H:%M:%S");
        ReplaceString(sText, sizeof(sText), "{time24}", sBuffer, false);
    }

    if (StrContains(sText, "{timeleft}", false) != -1) {
        int iMins, iSecs, iTimeLeft;
        if (GetMapTimeLeft(iTimeLeft) && iTimeLeft > 0) {
            iMins = iTimeLeft / 60;
            iSecs = iTimeLeft % 60;
        }

        Format(sBuffer, sizeof(sBuffer), "%d:%02d", iMins, iSecs);
        ReplaceString(sText, sizeof(sText), "{timeleft}", sBuffer, false);
    }

    ConVar hConVar;
    char sConVar[64], sSearch[64], sReplace[256];
    int iEnd = -1, iStart = StrContains(sText, "{"), iStart2;
    while (iStart != -1) {
        iEnd = StrContains(sText[iStart + 1], "}");
        if (iEnd == -1) {
            break;
        }

        strcopy(sConVar, iEnd + 1, sText[iStart + 1]);
        Format(sSearch, sizeof(sSearch), "{%s}", sConVar);

        if ((hConVar = FindConVar(sConVar))) {
            hConVar.GetString(sReplace, sizeof(sReplace));
            ReplaceString(sText, sizeof(sText), sSearch, sReplace, false);
        }

        iStart2 = StrContains(sText[iStart + 1], "{");
        if (iStart2 == -1) {
            break;
        }

        iStart += iStart2 + 1;
    }
}

void RestartTimer()
{
    delete g_hTimer;
    g_hTimer = CreateTimer(float(g_hCvarInterval.IntValue), Timer_DisplayAd, _, TIMER_REPEAT);
}
