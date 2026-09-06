-- Tranexamic acid: antifibrinolytic -- stops every body part's bleeding
-- outright. Side effect: moderate head pain.
function TakeTranexamicAcid(player)
    EMDrug_StopAllBleeding(player)
    EMDrug_GetHeadPart(player):setAdditionalPain(math.min(
        EMDrug_GetHeadPart(player):getAdditionalPain() + 30.0, 100.0))
end
