-- Naloxone hydrochloride: -"NaloxoneAddictionReduce" addiction
-- (default 0.25), +"NaloxoneHungerThirst" hunger and thirst
-- (HUNGER/THIRST are CharacterStats in 0..1).
function InjectNaloxone(player)
    EMDrug_ChangeAddiction(player, -EM_Sandbox_Get("NaloxoneAddictionReduce"))
    local hungerThirst = EM_Sandbox_Get("NaloxoneHungerThirst")
    local stats = player:getStats()
    stats:set(CharacterStat.HUNGER, math.min(1.0, stats:get(CharacterStat.HUNGER) + hungerThirst))
    stats:set(CharacterStat.THIRST, math.min(1.0, stats:get(CharacterStat.THIRST) + hungerThirst))
end
