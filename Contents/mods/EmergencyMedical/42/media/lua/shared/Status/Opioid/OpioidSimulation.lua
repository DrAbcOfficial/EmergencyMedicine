-- EmergencyMedical: the coupled addiction/withdrawal per-minute
-- simulation. Pure dynamics -- the value APIs live in
-- OpioidAddiction.lua / OpioidWithdrawal.lua; the shared
-- chase/fall/grind core in EM_Dependence.lua (EM_Dependence_TickCore).
--
-- Runs on the server for online players and on the local client (same
-- rate both sides); values reach the server via transmitModData() on
-- injection. Purely local-player on the client side.
--
-- Rules, every game minute:
-- * withdrawal chases the addiction baseline: while below it, it climbs
--   at baseline*(1/180) per minute -- whatever the gap, it closes within
--   3 game hours; while above it (fresh relief), it wears off toward the
--   baseline at 0.0002/min -- deliberately slower than the cold-turkey
--   decay, so a full baseline can burn down to zero inside one severe
--   stretch;
-- * only severe withdrawal (>= EM_Withdrawal_GetSevereLevel()) grinds
--   the baseline down, 0.0005 per minute;
-- * when the baseline reaches zero, the withdrawal ends immediately.
--
-- Math notes (deliberate design, not bugs): full addiction burns to zero
-- in 2000 minutes (~33 game hours) of untreated severe withdrawal; a
-- partial cold turkey from baseline p in (0.5, 0.83) floors at
-- 1.25 - 1.5*p and needs another high before the next grind.

-- The rates are sandbox-configurable, read every tick so option changes
-- apply from the next game minute on. "WithdrawalFallRate" and
-- "AddictionDecayRate" are fractions of the full value PER GAME DAY
-- (defaults 0.288 / 0.72); the core converts them to the per-minute
-- decimals by dividing by 1440 (0.0002 / 0.0005 per minute as before).

-- modData keys -- must match OpioidAddiction.lua / OpioidWithdrawal.lua
local ADDICTION_KEY = "EM_OpioidAddiction"
local WITHDRAWAL_KEY = "EM_OpioidWithdrawal"

local function minuteTick(player)
    if player == nil then
        return
    end
    EM_Dependence_TickCore(player,
        ADDICTION_KEY,
        WITHDRAWAL_KEY,
        EM_Withdrawal_GetSevereLevel(),
        EM_Sandbox_Get("WithdrawalClimbMinutes"),
        EM_Sandbox_Get("WithdrawalFallRate"),
        EM_Sandbox_Get("AddictionDecayRate"))
    -- opioid withdrawal accumulates the generic Somnolence status
    -- (drowsiness with teeth -- DrugEffectSimulation floors FATIGUE by
    -- its progress): one progress add per game hour, self-clocked off
    -- the record's applied time, on top of the status's natural decay
    if EM_Dependence_Get(player, WITHDRAWAL_KEY) > 0 then
        local now = player:getHoursSurvived()
        local somnolence = EM_TimedStatus.Get(player, EM_DrugFx_DATA_KEY, nil, "Somnolence")
        if somnolence == nil or now - somnolence.applied >= 1.0 then
            EM_DrugFx_Add(player, "Somnolence", nil, EM_Sandbox_Get("OpioidWithdrawalSomnolencePerHour"))
        end
    end
end

EM_Sim.EveryOneMinute(minuteTick)
