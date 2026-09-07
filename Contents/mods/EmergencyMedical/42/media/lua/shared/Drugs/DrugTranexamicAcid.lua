-- Tranexamic acid: antifibrinolytic -- stops every body part's bleeding
-- outright. Side effect: moderate head pain.
local HEAD_PAIN = 30.0

function TakeTranexamicAcid(player)
    EMDrug_StopAllBleeding(player)
    EMDrug_HeadPain(player, HEAD_PAIN)
end
