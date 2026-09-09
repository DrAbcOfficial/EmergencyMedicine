-- Sulfadimidine: sulfonamide antibiotic -- clears a share of every
-- part's LOCAL wound infection per dose (NOT the Knox virus), and the
-- cleared amount lands on the part as extra wound severity at half
-- weight (a heavy infection heals into a heavy wound). Side effects:
-- severe head pain, a sustained course fever (DrugEffectSimulation pins
-- the temperature against the thermoregulator's pull back to 37),
-- kidney strain and nausea.
local HEAD_PAIN = 70.0
local CLEAR_RATIO = 0.65        -- share of woundInfectionLevel cleared per dose
local TRANSFER_FACTOR = 0.5     -- cleared infection -> wound severity, at half weight
local KIDNEY_HEALTH = 4.0       -- general health taxed per dose
local NAUSEA = 12.0             -- FOOD_SICKNESS bump (0..100, self-decays)

function TakeSulfadimidine(player)
    EMDrug_ClearWoundInfectionProportional(player, CLEAR_RATIO, TRANSFER_FACTOR)
    EMDrug_HeadPain(player, HEAD_PAIN)
    -- course fever status: DrugEffectSimulation pins the temperature
    -- between 37 and the peak by status level (instant set so it starts)
    player:getStats():set(CharacterStat.TEMPERATURE, EM_DRUG_FEVER_TEMPERATURE)
    EM_DrugFx_Add(player, "DrugFever", { tempFloor = EM_DRUG_FEVER_TEMPERATURE })
    player:getBodyDamage():ReduceGeneralHealth(KIDNEY_HEALTH)
    EMDrug_AddFoodSickness(player, NAUSEA)
end
