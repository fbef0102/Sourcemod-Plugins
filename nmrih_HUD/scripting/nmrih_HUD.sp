//此插件占用的Hud Channel
// 0 - 血量/體力/感染狀態
// 1 - 速度
// 2 - 槍械彈夾與彈藥

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = {
    name = "[No More] Status Hud",
    author = "clagura, Grey83, Harry",
    description = "Display health, stamina, speed, infected status, ammo on hud",
    version = "1.1h-2025/2/10",
    url = "https://github.com/clague/plugin-source/blob/master/addons/sourcemod/scripting/HUD.sp"
};

bool g_bLateLoad;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    g_bLateLoad = late;
    CreateNative("NativeSetChannelDisabled", NativeSetChannelDisabled);
    return APLRes_Success;
}

ConVar g_hSpeedMeter, g_hDisplayHealth, g_hDisplaySpeed, g_hDisplayAmmo;
bool g_bSpeedMeter, g_bDisplayHealth, g_bDisplaySpeed;
int g_iDisplayAmmo;

bool g_aChannelEnable[6], g_aChannelUsed[6], g_aSpeedMetterEnabled[MAXPLAYERS + 1];
int iHealthChannel = 0, iSpeedChannel = 1, iAmmoChannel = 2,
    m_iPrimaryAmmoType,
    m_iClip1, m_iAmmo;
int g_aObserveTarget[16];
ArrayList g_aObserveAudience[MAXPLAYERS + 1];

static const char AMMO[][]	=
{
	"",
	"9mm",		// 1
	".45 ACP",	// 2
	".357",		// 3
	"12 Gauge",	// 4
	".22 LR",	// 5
	".308",		// 6
	"5.56mm",	// 7
	"7.62x39",	// 8
	"M67",		// 9
	"Molotov",	// 10
	"TNT",		// 11
	"Arrow",	// 12
	"Fuel",		// 13
	"Boards",	// 14
	"Flare"		// 15
};

public void OnPluginStart()
{
    LoadTranslations("nmrih_HUD.phrases");

    m_iPrimaryAmmoType	= FindSendPropInfo("CNMRiH_WeaponBase", "m_iPrimaryAmmoType");
    m_iClip1 = FindSendPropInfo("CNMRiH_WeaponBase", "m_iClip1");
    m_iAmmo = FindSendPropInfo("CNMRiH_Player", "m_iAmmo");

    g_hDisplayHealth    = CreateConVar("nmrih_HUD_display_health",  "1", "1=Display health, stamina, infected status in the HUD. 0=Off", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hDisplaySpeed     = CreateConVar("nmrih_HUD_display_speed",   "1", "1=Display speed meter in the HUD. 0=Off", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_hDisplayAmmo      = CreateConVar("nmrih_HUD_display_ammo",    "0", "1=Always display weapon clip/ammo in the HUD. 0=Show only clip number or ammo number changes, -1=Off", FCVAR_NOTIFY, true, -1.0, true, 1.0);
    g_hSpeedMeter       = CreateConVar("nmrih_HUD_speed_default",   "0", "1=Active the speed hud for client by default, 0=Disable the speed hud for client by default", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    AutoExecConfig(true,                "nmrih_HUD");

    GetCvars();
    g_hDisplayHealth.AddChangeHook(OnConVarChange);
    g_hDisplaySpeed.AddChangeHook(OnConVarChange);
    g_hDisplayAmmo.AddChangeHook(OnConVarChange);
    g_hSpeedMeter.AddChangeHook(OnConVarChange);

    RegConsoleCmd("sm_speed", CommandSpeed, "Enable/Disable Speed Hud");

    HookEvent("player_disconnect", Event_PlayerDisconnect);
    HookEvent("weapon_fired",	Event_Weapon);
    HookEvent("weapon_reload",	Event_Weapon);

    for (int i = 0; i < 6; i++) {
        g_aChannelEnable[i] = true;
        g_aChannelUsed[i] = false;
    }

    iHealthChannel = 0;
    iSpeedChannel = 1;
    iAmmoChannel = 2;

    CreateTimer(0.25, Repeat_Print, _, TIMER_REPEAT);
    CreateTimer(0.25, SendExtraMsg, _, TIMER_REPEAT);
    CreateTimer(1.0, Timer_UpdateAmmo, _, TIMER_REPEAT);

    if(g_bLateLoad)
    {
        LateLoad();
    }
}

void LateLoad()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        OnClientPutInServer(client);
    }
}

void OnConVarChange(ConVar CVar, const char[] oldValue, const char[] newValue) 
{
    GetCvars();
}

void GetCvars()
{
    g_bDisplayHealth = g_hDisplayHealth.BoolValue;
    g_bDisplaySpeed = g_hDisplaySpeed.BoolValue;
    g_iDisplayAmmo = g_hDisplayAmmo.IntValue;
    g_bSpeedMeter = g_hSpeedMeter.BoolValue;
}

bool g_bFirst = true;
public void OnConfigsExecuted()
{
    GetCvars();

    if(g_bFirst)
    {
        g_bFirst = false;
        for(int i = 1; i <= MaxClients; i++)
        {
            g_aSpeedMetterEnabled[i] = g_bSpeedMeter;
        }
    }
}

public void OnMapStart()
{
    for (int i = 0; i < 6; i++) {
        g_aChannelEnable[i] = true;
    } 
}

public void OnClientPutInServer(int client) 
{
    g_aObserveTarget[client] = 0;
    if (IsValidHandle(g_aObserveAudience[client])) {
        g_aObserveAudience[client].Clear();
    }
    else {
        g_aObserveAudience[client] = new ArrayList();
    }

    if(IsFakeClient(client)) return;

    SDKHook(client, SDKHook_WeaponSwitchPost, Hook_Switch);
    SDKHook(client, SDKHook_WeaponDropPost, Hook_Drop);
    //SDKHook_FireBulletsPost沒觸發
    //SDKHook(client, SDKHook_FireBulletsPost, Hook_Fire);
}

public void OnClientDisconnect(int iClient) {
    int iTemp;
    if (g_aObserveTarget[iClient] > 0 && (iTemp = g_aObserveAudience[g_aObserveTarget[iClient]].FindValue(iClient)) != -1) {
        g_aObserveAudience[g_aObserveTarget[iClient]].Erase(iTemp);
    }
}

Action CommandSpeed(int iClient, int args) 
{
    if(g_aSpeedMetterEnabled[iClient]) 
    {
        g_aSpeedMetterEnabled[iClient] = false;
        PrintToChat(iClient, "%T", "Speed Off", iClient);
    }
    else {
        g_aSpeedMetterEnabled[iClient] = true;
        PrintToChat(iClient, "%T", "Speed On", iClient);
    }
    return Plugin_Handled;
}

void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	g_aSpeedMetterEnabled[client] = g_bSpeedMeter;
}

void Event_Weapon(Event event, const char[] name, bool dontBroadcast)
{
	int client = event.GetInt("player_id");
	if(name[7] == 'r') client = GetClientOfUserId(client);
	if(0 < client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client)) ShowAmmo(client);
}

void Hook_Switch(int client, int weapon)
{
	ShowAmmo(client);
}

void Hook_Drop(int client, int weapon)
{
	ShowAmmo(client);
}

/*void Hook_Fire(int client, int shots, const char[] weaponname)
{
    ShowAmmo(client);
}*/

int NativeSetChannelDisabled(Handle plugin, int num_params) {
    int n = GetNativeCell(1);
    g_aChannelEnable[n] = false;

    if (iHealthChannel == n) {
        g_aChannelUsed[iHealthChannel] = false;
        iHealthChannel = ChooseChannel();
        g_aChannelUsed[iHealthChannel] = true;
    }
    if (iSpeedChannel == n) {
        g_aChannelUsed[iSpeedChannel] = false;
        iSpeedChannel = ChooseChannel();
        g_aChannelUsed[iSpeedChannel] = true;
    }
    if (iAmmoChannel == n) {
        g_aChannelUsed[iAmmoChannel] = false;
        iAmmoChannel = ChooseChannel();
        g_aChannelUsed[iAmmoChannel] = true;
    }
    return 0;
}

int ChooseChannel() {
    for (int i = 2; i < 6; i++) { //channel 1 is much used for map text, so skip it
        if (g_aChannelEnable[i] && !g_aChannelUsed[i]) {
            return i;
        }
    }
    return 0;
}

int GetHUDTarget(int iClient)
{
    if (IsClientObserver(iClient))
    {
        int iObserverMode = GetEntProp(iClient, Prop_Send, "m_iObserverMode");
        if (iObserverMode >= 3 && iObserverMode <= 5)
        {
            int iTarget = GetEntPropEnt(iClient, Prop_Send, "m_hObserverTarget");
            if (iTarget > 0 && iTarget <= MaxClients && IsClientInGame(iTarget) && !IsClientSourceTV(iTarget)) {
                if (iTarget != g_aObserveTarget[iClient]) {
                    int iTemp;
                    if (g_aObserveTarget[iClient] != 0 && (iTemp = g_aObserveAudience[g_aObserveTarget[iClient]].FindValue(iClient)) != -1) {
                        g_aObserveAudience[g_aObserveTarget[iClient]].Erase(iTemp);
                    }
                    g_aObserveTarget[iClient] = iTarget;
                    if (g_aObserveAudience[iTarget].FindValue(iClient) == -1) {
                        g_aObserveAudience[iTarget].Push(iClient);
                    }
                }
                return iTarget;
            }
        }
    }
    int iTemp;
    if (g_aObserveTarget[iClient] != 0 && (iTemp = g_aObserveAudience[g_aObserveTarget[iClient]].FindValue(iClient)) != -1) {
        g_aObserveAudience[g_aObserveTarget[iClient]].Erase(iTemp);
    }
    g_aObserveTarget[iClient] = 0;
    return iClient;
}

// Hud Refresh Timer

Action Repeat_Print(Handle hTimer)
{
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i)) {
            GetHUDTarget(i);
        }
    }
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && !IsClientTimingOut(i) && IsPlayerAlive(i))
        {
            static int aClients[MAXPLAYERS + 1], nClients;
            nClients = 0;
            for (int j = 0; j < g_aObserveAudience[i].Length; j++) {
                aClients[nClients++] = g_aObserveAudience[i].Get(j);
            }
            aClients[nClients++] = i;
            SendHealthMessage(i, aClients, nClients);
            if (g_aSpeedMetterEnabled[i]) {
                SendSpeedMessage(i, aClients, nClients);
            }
        }
    }
    return Plugin_Continue;
}

Action SendExtraMsg(Handle timer) 
{
    static int aClients[MAXPLAYERS + 1], nClients;
    for (int i = 1; i <= MaxClients; i++) 
    {
        if (IsClientInGame(i) && IsPlayerAlive(i) && g_aObserveAudience[i].Length > 0) 
        {
            nClients = 0;
            for (int j = 0; j < g_aObserveAudience[i].Length; j++) {
                aClients[nClients++] = g_aObserveAudience[i].Get(j);
                //PrintToServer("%N's audience: %d", i, g_aObserveAudience[i].Get(j));
            }
            Handle hMsg = StartMessage("KeyHintText", aClients, nClients, USERMSG_BLOCKHOOKS);
            BfWrite bf = UserMessageToBfWrite(hMsg);
            bf.WriteByte(1); // number of strings, only 1 is accepted

            char szBuffer[256];
            FormatEx(szBuffer, sizeof(szBuffer), "%T", "Spectating", LANG_SERVER, i);
            for (int j = 0; j < g_aObserveAudience[i].Length; j++) {
                Format(szBuffer, sizeof(szBuffer), "%s%N\n", szBuffer, g_aObserveAudience[i].Get(j));
            }
            bf.WriteString(szBuffer);
            EndMessage();
        }
    }

    return Plugin_Continue;
}

Action Timer_UpdateAmmo(Handle timer)
{
    if(g_iDisplayAmmo <= 0) return Plugin_Continue;

    for(int i = 1; i <= MaxClients; i++) 
    { 
        if(IsClientInGame(i) && IsPlayerAlive(i)) 
        {
            ShowAmmo(i);
        }
    }

    return Plugin_Continue;
}

// Display HUD

void SendHealthMessage(int iClient, int[] aClients, int nClients) 
{
    if(!g_bDisplayHealth) return;

    static int iHealth;
    iHealth = GetClientHealth(iClient);
    static char szHealthText[128], szStatusText[128];

    FormatEx(szHealthText, sizeof(szHealthText), "%T", "Health", iClient, iHealth);

    if (!g_bSpeedMeter) {
        static int iStamina;
        iStamina = RoundToZero(GetEntPropFloat(iClient, Prop_Send, "m_flStamina", 0));

        Format(szHealthText, sizeof(szHealthText), "%s    %T", szHealthText, "Stamina", iClient, iStamina);

        szStatusText[0] = 0;
        if(GetEntProp(iClient, Prop_Send, "_bleedingOut") == 1)
        {
            Format(szStatusText, sizeof(szStatusText), "%s%T ", szStatusText, "bleeding", iClient);
        }

        if(GetEntProp(iClient, Prop_Send, "_vaccinated") == 1)
        {
            Format(szStatusText, sizeof(szStatusText), "%s%T ", szStatusText, "vaccinated", iClient);
        }
        else 
        {
            float fInfection_Death_Time = GetEntPropFloat(iClient, Prop_Send, "m_flInfectionDeathTime");
            if(fInfection_Death_Time != -1.0)
            {
                Format(szStatusText, sizeof(szStatusText), "%s%T ", szStatusText, "infected", iClient, RoundToCeil(fInfection_Death_Time - GetGameTime()));
            }
        }
    }

    static int iTextColor_r, iTextColor_g, iTextColor_b;
    iTextColor_b = 0;
    if (iHealth > 99)		// 100
    {
        iTextColor_r = 0;
        iTextColor_g = 255;
    }
    else if (iHealth > 66)		// 99 - 67
    {
        iTextColor_r = RoundToNearest(((100.0 - float(iHealth)) / 34.0) * 255.0);
        iTextColor_g = 255;
    }
    else if (iHealth > 33)		// 66 - 34
    {
        iTextColor_r = 255;
        iTextColor_g = RoundToNearest((float(iHealth) - 33.0) / 33.0 * 255.0);
    }
    else		// 33 - 0
    {
        iTextColor_r = 255;
        iTextColor_g = 0;
    }
    Format(szHealthText, sizeof(szHealthText), "%s\n%s", szHealthText, szStatusText);

    Handle hHealthMsg = StartMessage("HudMsg", aClients, nClients, USERMSG_BLOCKHOOKS); //Surely block hooks
    BfWrite bf = UserMessageToBfWrite(hHealthMsg);
    bf.WriteByte(iHealthChannel);
    bf.WriteFloat(0.02); // x
    bf.WriteFloat(0.86); // y
    bf.WriteByte(iTextColor_r);
    bf.WriteByte(iTextColor_g);
    bf.WriteByte(iTextColor_b);
    bf.WriteByte(255);
    bf.WriteByte(iTextColor_r);
    bf.WriteByte(iTextColor_g);
    bf.WriteByte(iTextColor_b);
    bf.WriteByte(255);
    bf.WriteByte(1);
    bf.WriteFloat(0.2);
    bf.WriteFloat(0.3);
    bf.WriteFloat(0.5); // print time
    bf.WriteFloat(0.0);
    bf.WriteString(szHealthText);
    EndMessage();
}

void SendSpeedMessage(int iClient, int[] aClients, int nClients) 
{
    if(!g_bDisplaySpeed) return;

    static float vecVelocity[3], fSpeed;
    GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", vecVelocity);
    
    vecVelocity[0] *= vecVelocity[0];
    vecVelocity[1] *= vecVelocity[1];
    vecVelocity[2] *= vecVelocity[2];
    
    fSpeed = SquareRoot(vecVelocity[0] + vecVelocity[1] + vecVelocity[2]);
    if(fSpeed <= 0.0) return;
    
    static char szSpeedText[100];
    FormatEx(szSpeedText, sizeof(szSpeedText), "%T", "Speed", iClient, fSpeed);

    Handle hSpeedMsg = StartMessage("HudMsg", aClients, nClients, USERMSG_BLOCKHOOKS); //Surely block hooks
    BfWrite bf = UserMessageToBfWrite(hSpeedMsg);
    bf.WriteByte(iSpeedChannel);
    bf.WriteFloat(-1.0);
    bf.WriteFloat(0.85);
    bf.WriteByte(255);
    bf.WriteByte(255);
    bf.WriteByte(255);
    bf.WriteByte(255);
    bf.WriteByte(255);
    bf.WriteByte(255);
    bf.WriteByte(255);
    bf.WriteByte(255);
    bf.WriteByte(0);
    bf.WriteFloat(0.0);
    bf.WriteFloat(0.0);
    bf.WriteFloat(0.5);
    bf.WriteFloat(0.0);
    bf.WriteString(szSpeedText);
    EndMessage();
}

void ShowAmmo(int client)
{
    if(g_iDisplayAmmo < 0) return;

    int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if(weapon <= MaxClients || !IsValidEntity(weapon)) return;

    static int type;
    static char txt[20];
    type = GetEntData(weapon, m_iPrimaryAmmoType);
    if(type == -1)
    {
        if(!GetEntityClassname(weapon, txt, sizeof(txt)) || txt[0] != 'i') return;

        switch(txt[5])
        {
            case 'b': FormatEx(txt, sizeof(txt), "Bandages\n ");
            case 'f': FormatEx(txt, sizeof(txt), "First Aid\n ");
            case 'g':
            {
                if(txt[6] != 'e') return;

                FormatEx(txt, sizeof(txt), "Gene Therapy\n ");
            }
            case 'p': FormatEx(txt, sizeof(txt), "Pills\n ");
            default: return;
        }
    }
    else if( 0 < type && type < 9 || 11 < type && type < sizeof(AMMO))
    {
        FormatEx(txt, sizeof(txt), "%s\n%i / %i", AMMO[type], GetEntData(weapon, m_iClip1), GetEntData(client, (m_iAmmo + (type << 2))));
    }
    else return;

    SetHudTextParams(-0.02, 0.90, 1.0, 204, 204, 204, 127, 1, 0.5, 0.2, 0.3);
    ShowHudText(client, iAmmoChannel, txt);
}