-- Morphine: instant full heal (health only -- wounds untouched), the
-- vanilla painkiller state at full strength, boredom/unhappiness/panic
-- wiped, then the shared injection entry (+0.5 addiction, -0.35
-- withdrawal relief, modData sync).
function InjectMorphine(player)
    EMDrug_HealToFull(player)
    EMDrug_FullPainkiller(player)
    EMDrug_ClearMind(player)
    EM_Addiction_UseInjection(player)
end
