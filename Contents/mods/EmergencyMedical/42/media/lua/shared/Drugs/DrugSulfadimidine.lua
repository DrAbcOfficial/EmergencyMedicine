-- Sulfadimidine: sulfonamide antibiotic -- clears a share of every
-- part's LOCAL wound infection per dose (NOT the Knox virus), and the
-- cleared amount lands on the part as extra wound severity at half
-- weight (a heavy infection heals into a heavy wound). Side effects:
-- severe head pain, a sustained course fever (BodyWoundSimulation pins
-- the temperature against the thermoregulator's pull back to 37),
-- kidney strain and nausea.
local HEAD_PAIN = 70.0
local CLEAR_RATIO = 0.65        -- share of woundInfectionLevel cleared per dose
local TRANSFER_FACTOR = 0.5     -- cleared infection -> wound severity, at half weight
local FEVER_TEMPERATURE = 38.5  -- DrugFever temperature floor
local FEVER_HOURS = 12.0
local KIDNEY_HEALTH = 4.0       -- general health taxed per dose
local NAUSEA = 12.0             -- FOOD_SICKNESS bump (0..100, self-decays)

function TakeSulfadimidine(player)
    EMDrug_ClearWoundInfectionProportional(player, CLEAR_RATIO, TRANSFER_FACTOR)
    EMDrug_HeadPain(player, HEAD_PAIN)
    -- course fever: state on the head keeps the temperature pinned at
    -- its tempFloor custom param (instant set so it starts now)
    player:getStats():set(CharacterStat.TEMPERATURE, FEVER_TEMPERATURE)
    local head = EMDrug_GetHeadPart(player)
    local state = EM_Wound_Add(player, head, "DrugFever", FEVER_HOURS / EM_CONST.HOURS_PER_GAME_DAY)
    if state ~= nil then
        state.tempFloor = FEVER_TEMPERATURE
    end
    player:getBodyDamage():ReduceGeneralHealth(KIDNEY_HEALTH)
    EMDrug_AddFoodSickness(player, NAUSEA)
end
