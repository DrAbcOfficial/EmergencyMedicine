-- EmergencyMedical: the coupled addiction/withdrawal per-minute
-- simulation. Pure dynamics -- the value APIs live in
-- OpioidAddiction.lua / OpioidWithdrawal.lua.
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
-- (defaults 0.288 / 0.72); they are converted to the per-minute decimals
-- by dividing by 1440 (0.0002 / 0.0005 per minute as before).

local function minuteTick(player)
    if player == nil then
        return
    end
    local addiction = EM_Addiction_Get(player)
    -- No baseline, no sickness: withdrawal ends immediately.
    if addiction <= 0 then
        EM_Withdrawal_Set(player, 0)
        return
    end
    local withdrawal = EM_Withdrawal_Get(player)
    -- Withdrawal chases the baseline: climbs fast while below it (the
    -- whole gap closes within the configured climb time), wears off
    -- slowly above it.
    local newWithdrawal = withdrawal
    if withdrawal < addiction then
        local climbMinutes = EM_Sandbox_Get("WithdrawalClimbMinutes")
        newWithdrawal = math.min(addiction, withdrawal + addiction / math.max(climbMinutes, 1))
    elseif withdrawal > addiction then
        newWithdrawal = math.max(addiction, withdrawal - EM_Sandbox_Get("WithdrawalFallRate") / 1440)
    end
    if newWithdrawal ~= withdrawal then
        EM_Withdrawal_Set(player, newWithdrawal)
    end
    -- Only severe withdrawal (cold turkey) grinds the baseline down.
    if newWithdrawal >= EM_Withdrawal_GetSevereLevel() then
        EM_Addiction_Set(player, addiction - EM_Sandbox_Get("AddictionDecayRate") / 1440)
        if EM_Addiction_Get(player) <= 0 then
            EM_Withdrawal_Set(player, 0)
        end
    end
end

local function simulate()
    if isServer() then
        local players = getOnlinePlayers()
        for i = 0, players:size() - 1 do
            minuteTick(players:get(i))
        end
    else
        local player = getSpecificPlayer(0)
        if player ~= nil and player:isLocalPlayer() then
            minuteTick(player)
        end
    end
end

Events.EveryOneMinute.Add(simulate)
