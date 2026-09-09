-- Naloxone hydrochloride: -"NaloxoneAddictionReduce" addiction
-- (default 0.25), +"NaloxoneHungerThirst" hunger and thirst
-- (HUNGER/THIRST are CharacterStats in 0..1).
function InjectNaloxone(player)
    EMDrug_ChangeAddiction(player, -EM_Sandbox_Get("NaloxoneAddictionReduce"))
    local hungerThirst = EM_Sandbox_Get("NaloxoneHungerThirst")
    local stats = player:getStats()
    stats:set(CharacterStat.HUNGER, math.min(EM_CONST.STAT_SCALE_MAX, stats:get(CharacterStat.HUNGER) + hungerThirst))
    stats:set(CharacterStat.THIRST, math.min(EM_CONST.STAT_SCALE_MAX, stats:get(CharacterStat.THIRST) + hungerThirst))
end
