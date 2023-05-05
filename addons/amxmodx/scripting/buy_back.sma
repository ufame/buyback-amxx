#include <amxmodx>
#include <reapi>

new const BUYBACK_SOUND[] = "buy_back.wav"

enum settings_struct {
  setting_base_cost,
  bool: setting_increase_by_frags,
  setting_increase_by_frags_money,
  setting_restrict_round,
  setting_restrict_rounds_count,
}

new g_buybackSettings[settings_struct]
new g_lastBuyback[MAX_PLAYERS + 1]
new g_roundBuybacks[MAX_PLAYERS + 1]

new mp_maxmoney

public plugin_precache() {
  precache_sound(BUYBACK_SOUND)
}

public plugin_init() {
  register_plugin("Buy Back", "1.0.0", "ufame")

  register_dictionary("buy_back.txt")

  createCvars()
  mp_maxmoney = get_cvar_num("mp_maxmoney")

  register_clcmd("bb", "commandBuyback")
  register_clcmd("say .bb", "commandBuyback")
  register_clcmd("say /bb", "commandBuyback")

  if (g_buybackSettings[setting_restrict_round])
    RegisterHookChain(RG_CSGameRules_RestartRound, "roundRestart", .post = 1)
}

public commandBuyback(id) {
  if (get_member(id, m_iTeam) == TEAM_UNASSIGNED || get_member(id, m_iTeam) == TEAM_SPECTATOR)
    return PLUGIN_HANDLED

  new currentRound = (get_member_game(m_iTotalRoundsPlayed) + 1)
  if (
    g_buybackSettings[setting_restrict_round] &&
    currentRound - g_lastBuyback[id] > g_buybackSettings[setting_restrict_rounds_count]
  ) {
    return PLUGIN_HANDLED
  }

  new cost = g_buybackSettings[setting_base_cost]

  if (g_buybackSettings[setting_increase_by_frags]) {
    new frags = floatround(get_entvar(id, var_frags))
    cost += (frags * g_buybackSettings[setting_increase_by_frags_money])
  }

  if (cost > mp_maxmoney)
    cost = mp_maxmoney

  new money = get_member(id, m_iAccount)

  if (money < cost) {
    client_print_color(id, print_team_default, "%L", id, "BB_NO_ENOUGH_MONEY", cost - money)

    return PLUGIN_HANDLED
  }

  rg_add_account(id, -cost)
  rg_round_respawn(id)

  if (g_buybackSettings[setting_restrict_round])
    g_lastBuyback[id] = currentRound

  #if defined BUYBACK_SOUND
    rg_send_audio(0, BUYBACK_SOUND)
  #endif

  client_print_color(0, print_team_default, "%L", LANG_PLAYER, "BB_RESPAWNED", id)

  return PLUGIN_HANDLED
}

public roundRestart() {
  for (new i = 1; i <= MaxClients; i++)
    if (is_user_connected(i)) g_roundBuybacks[i] = 0;
}

createCvars() {
  bind_pcvar_num(create_cvar("bb_base_cost", "1000", _, "Default buy back cost"), g_buybackSettings[setting_base_cost])
  bind_pcvar_num(create_cvar("bb_increase_by_frags", "1", _, "Increase buy back cost by player frags?"), g_buybackSettings[setting_increase_by_frags])
  bind_pcvar_num(create_cvar("bb_increase_by_frags_money", "200", _, "By how much does the cost for each frag increase"), g_buybackSettings[setting_increase_by_frags_money])
  bind_pcvar_num(create_cvar("bb_restrict_round", "1", _, "Increase buy back cost by player frags?"), g_buybackSettings[setting_increase_by_frags])
  bind_pcvar_num(create_cvar("bb_restrict_rounds_count", "5", _, "Increase buy back cost by player frags?"), g_buybackSettings[setting_increase_by_frags])

  AutoExecConfig(.name = "buy_back")
}
