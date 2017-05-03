#include <amxmodx>
#include <amxmisc>
#include <reapi>

#define PLUGIN_VERSION "1.1"

enum _:PlayerRewards
{
	RewardType:Type,
	Math[16],
	Round[16],
	Flags
}

new const g_szAll[] = "#all"

new Array:g_aPlayerRewards,
	g_szMap[32],
	g_iCurrentRound,
	g_iTotalPlayerRewards

public plugin_init()
{
	register_plugin("Money Rewards Modifier", PLUGIN_VERSION, "OciXCrom")
	register_cvar("CRXMoneyModifier", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "ReAPI_HC_OnRoundFreezeEnd")
	RegisterHookChain(RG_CBasePlayer_AddAccount, "ReAPI_HC_AddAccount_Pre")	
	get_mapname(g_szMap, charsmax(g_szMap))
	g_aPlayerRewards = ArrayCreate(PlayerRewards)
	ReadFile()
}

public plugin_end()
	ArrayDestroy(g_aPlayerRewards)

ReadFile()
{
	new szConfigsName[256], szFilename[256]
	get_configsdir(szConfigsName, charsmax(szConfigsName))
	formatex(szFilename, charsmax(szFilename), "%s/MoneyModifier.ini", szConfigsName)
	new iFilePointer = fopen(szFilename, "rt")
	
	if(iFilePointer)
	{
		new szData[96], szValue[64], szKey[32], bool:bRead = true, iSize
		new eReward[PlayerRewards], szFlags[32]
		
		while(!feof(iFilePointer))
		{
			fgets(iFilePointer, szData, charsmax(szData))
			trim(szData)
			
			switch(szData[0])
			{
				case EOS, ';': continue
				case '[':
				{
					iSize = strlen(szData)
					
					if(szData[iSize - 1] == ']')
					{
						szData[0] = ' '
						szData[iSize - 1] = ' '
						trim(szData)
						
						if(contain(szData, "*") != -1)
						{
							strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '*')
							copy(szValue, strlen(szKey), g_szMap)
							bRead = equal(szValue, szKey) ? true : false
						}
						else
							bRead = equal(szData, g_szAll) || equali(szData, g_szMap)
					}
					else continue
				}
				default:
				{
					if(!bRead)
						continue
						
					strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
					trim(szKey); trim(szValue)
					
					switch(szKey[1])
					{
						case 'T':
						{
							if(equali(szKey, "RT_ROUND_BONUS"))
								eReward[Type] = RT_ROUND_BONUS
							else if(equali(szKey, "RT_PLAYER_RESET"))
								eReward[Type] = RT_PLAYER_RESET
							else if(equali(szKey, "RT_PLAYER_JOIN"))
								eReward[Type] = RT_PLAYER_JOIN
							else if(equali(szKey, "RT_PLAYER_SPEC_JOIN"))
								eReward[Type] = RT_PLAYER_SPEC_JOIN
							else if(equali(szKey, "RT_PLAYER_BOUGHT_SOMETHING"))
								eReward[Type] = RT_PLAYER_BOUGHT_SOMETHING
							else if(equali(szKey, "RT_HOSTAGE_TOOK"))
								eReward[Type] = RT_HOSTAGE_TOOK
							else if(equali(szKey, "RT_HOSTAGE_RESCUED"))
								eReward[Type] = RT_HOSTAGE_RESCUED
							else if(equali(szKey, "RT_HOSTAGE_DAMAGED"))
								eReward[Type] = RT_HOSTAGE_DAMAGED
							else if(equali(szKey, "RT_HOSTAGE_KILLED"))
								eReward[Type] = RT_HOSTAGE_KILLED
							else if(equali(szKey, "RT_TEAMMATES_KILLED"))
								eReward[Type] = RT_TEAMMATES_KILLED
							else if(equali(szKey, "RT_ENEMY_KILLED"))
								eReward[Type] = RT_ENEMY_KILLED
							else if(equali(szKey, "RT_INTO_GAME"))
								eReward[Type] = RT_INTO_GAME
							else if(equali(szKey, "RT_VIP_KILLED"))
								eReward[Type] = RT_VIP_KILLED
							else if(equali(szKey, "RT_VIP_RESCUED_MYSELF"))
								eReward[Type] = RT_VIP_RESCUED_MYSELF
							else continue
							
							szFlags[0] = EOS
							eReward[Round][0] = EOS
							parse(szValue, eReward[Math], charsmax(eReward[Math]), eReward[Round], charsmax(eReward[Round]), szFlags, charsmax(szFlags))
							eReward[Flags] = szFlags[0] ? read_flags(szFlags) : ADMIN_ALL
							ArrayPushArray(g_aPlayerRewards, eReward)
							g_iTotalPlayerRewards++
						}
						case 'R':
						{
							if(equal(szKey, "RR_CTS_WIN"))
								rg_set_account_rules(RR_CTS_WIN, math_add(rg_get_account_rules(RR_CTS_WIN), szValue))
							else if(equal(szKey, "RR_TERRORISTS_WIN"))
								rg_set_account_rules(RR_TERRORISTS_WIN, math_add(rg_get_account_rules(RR_TERRORISTS_WIN), szValue))
							else if(equal(szKey, "RR_TARGET_BOMB"))
								rg_set_account_rules(RR_TARGET_BOMB, math_add(rg_get_account_rules(RR_TARGET_BOMB), szValue))
							else if(equal(szKey, "RR_VIP_ESCAPED"))
								rg_set_account_rules(RR_VIP_ESCAPED, math_add(rg_get_account_rules(RR_VIP_ESCAPED), szValue))
							else if(equal(szKey, "RR_VIP_ASSASSINATED"))
								rg_set_account_rules(RR_VIP_ASSASSINATED, math_add(rg_get_account_rules(RR_VIP_ASSASSINATED), szValue))
							else if(equal(szKey, "RR_TERRORISTS_ESCAPED"))
								rg_set_account_rules(RR_TERRORISTS_ESCAPED, math_add(rg_get_account_rules(RR_TERRORISTS_ESCAPED), szValue))
							else if(equal(szKey, "RR_CTS_PREVENT_ESCAPE"))
								rg_set_account_rules(RR_CTS_PREVENT_ESCAPE, math_add(rg_get_account_rules(RR_CTS_PREVENT_ESCAPE), szValue))
							else if(equal(szKey, "RR_ESCAPING_TERRORISTS_NEUTRALIZED"))
								rg_set_account_rules(RR_ESCAPING_TERRORISTS_NEUTRALIZED, math_add(rg_get_account_rules(RR_ESCAPING_TERRORISTS_NEUTRALIZED), szValue))
							else if(equal(szKey, "RR_BOMB_DEFUSED"))
								rg_set_account_rules(RR_BOMB_DEFUSED, math_add(rg_get_account_rules(RR_BOMB_DEFUSED), szValue))
							else if(equal(szKey, "RR_BOMB_PLANTED"))
								rg_set_account_rules(RR_BOMB_PLANTED, math_add(rg_get_account_rules(RR_BOMB_PLANTED), szValue))
							else if(equal(szKey, "RR_BOMB_EXPLODED"))
								rg_set_account_rules(RR_BOMB_EXPLODED, math_add(rg_get_account_rules(RR_BOMB_EXPLODED), szValue))
							else if(equal(szKey, "RR_ALL_HOSTAGES_RESCUED"))
								rg_set_account_rules(RR_ALL_HOSTAGES_RESCUED, math_add(rg_get_account_rules(RR_ALL_HOSTAGES_RESCUED), szValue))
							else if(equal(szKey, "RR_TARGET_BOMB_SAVED"))
								rg_set_account_rules(RR_TARGET_BOMB_SAVED, math_add(rg_get_account_rules(RR_TARGET_BOMB_SAVED), szValue))
							else if(equal(szKey, "RR_HOSTAGE_NOT_RESCUED"))
								rg_set_account_rules(RR_HOSTAGE_NOT_RESCUED, math_add(rg_get_account_rules(RR_HOSTAGE_NOT_RESCUED), szValue))
							else if(equal(szKey, "RR_VIP_NOT_ESCAPED"))
								rg_set_account_rules(RR_VIP_NOT_ESCAPED, math_add(rg_get_account_rules(RR_VIP_NOT_ESCAPED), szValue))
							else if(equal(szKey, "RR_LOSER_BONUS_DEFAULT"))
								rg_set_account_rules(RR_LOSER_BONUS_DEFAULT, math_add(rg_get_account_rules(RR_LOSER_BONUS_DEFAULT), szValue))
							else if(equal(szKey, "RR_LOSER_BONUS_MIN"))
								rg_set_account_rules(RR_LOSER_BONUS_MIN, math_add(rg_get_account_rules(RR_LOSER_BONUS_MIN), szValue))
							else if(equal(szKey, "RR_LOSER_BONUS_MAX"))
								rg_set_account_rules(RR_LOSER_BONUS_MAX, math_add(rg_get_account_rules(RR_LOSER_BONUS_MAX), szValue))
							else if(equal(szKey, "RR_LOSER_BONUS_ADD"))
								rg_set_account_rules(RR_LOSER_BONUS_ADD, math_add(rg_get_account_rules(RR_LOSER_BONUS_ADD), szValue))
							else if(equal(szKey, "RR_RESCUED_HOSTAGE"))
								rg_set_account_rules(RR_RESCUED_HOSTAGE, math_add(rg_get_account_rules(RR_RESCUED_HOSTAGE), szValue))
							else if(equal(szKey, "RR_TOOK_HOSTAGE_ACC"))
								rg_set_account_rules(RR_TOOK_HOSTAGE_ACC, math_add(rg_get_account_rules(RR_TOOK_HOSTAGE_ACC), szValue))
							else if(equal(szKey, "RR_TOOK_HOSTAGE"))
								rg_set_account_rules(RR_TOOK_HOSTAGE, math_add(rg_get_account_rules(RR_TOOK_HOSTAGE), szValue))
							else if(equal(szKey, "RR_END"))
								rg_set_account_rules(RR_END, math_add(rg_get_account_rules(RR_END), szValue))
						}
					}
				}
			}
		}
		
		fclose(iFilePointer)
	}
}

public ReAPI_HC_OnRoundFreezeEnd()
	g_iCurrentRound = get_member_game(m_iTotalRoundsPlayed) + 1
	
public ReAPI_HC_AddAccount_Pre(id, iAmount, RewardType:iType, bool:bChange)
{
	static eReward[PlayerRewards]
	new bool:bMatch
	
	for(new i, iFlags = get_user_flags(id); i < g_iTotalPlayerRewards; i++)
	{
		ArrayGetArray(g_aPlayerRewards, i, eReward)
		
		if(eReward[Type] == iType && is_valid_round(eReward[Round]) && iFlags & eReward[Flags] == eReward[Flags])
		{
			bMatch = true
			iAmount = math_add(iAmount, eReward[Math])
		}
	}
	
	if(bMatch)
		SetHookChainArg(2, ATYPE_INTEGER, iAmount)
}

bool:is_valid_round(const szRound[])
{
	if(!szRound[0] || szRound[0] == '0')
		return true
		
	if(contain(szRound, "-") != -1)
	{
		static szMin[4], szMax[4]
		strtok(szRound, szMin, charsmax(szMin), szMax, charsmax(szMax), '-')
		trim(szMin); trim(szMax)
		return str_to_num(szMin) <= g_iCurrentRound <= str_to_num(szMax)
	}
	else if(isdigit(szRound[0]))
		return g_iCurrentRound == str_to_num(szRound)
		
	static szNewRound[16], cOperator, iNum
	copy(szNewRound, charsmax(szNewRound), szRound)
	replace_all(szNewRound, charsmax(szNewRound), " ", "")
	cOperator = szRound[0]
	szNewRound[0] = ' '
	
	trim(szNewRound)
	iNum = str_to_num(szNewRound)
	
	switch(cOperator)
	{
		case '>': return g_iCurrentRound > iNum
		case '<': return g_iCurrentRound < iNum
	}
	
	return false
}

math_add(iNum, const szMath[])
{
	static szNewMath[16], bool:bPercent, cOperator, iMath
   
	copy(szNewMath, charsmax(szNewMath), szMath)
	bPercent = szNewMath[strlen(szNewMath) - 1] == '%'
	cOperator = szNewMath[0]
   
	if(!isdigit(cOperator))
		szNewMath[0] = ' '
   
	if(bPercent)
		replace(szNewMath, charsmax(szNewMath), "%", "")
	   
	trim(szNewMath)
	iMath = str_to_num(szNewMath)
   
	if(bPercent)
		iMath *= iNum / 100
	   
	switch(cOperator)
	{
		case '+': iNum += iMath
		case '-': iNum -= iMath
		case '/': iNum /= iMath
		case '*': iNum *= iMath
		default: iNum = iMath
	}
	
	return iNum
}