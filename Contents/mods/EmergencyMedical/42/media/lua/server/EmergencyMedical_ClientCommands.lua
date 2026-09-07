-- EmergencyMedical: server-side execution of the body-part wound
-- treatments. Body damage and player modData are server-authoritative in
-- B42 MP (the client-side syncBodyPart is a no-op, and the server streams
-- its BodyDamage copy over the owning client's), so the timed actions
-- send a client command instead of mutating the patient directly. This
-- mirrors the vanilla pattern in ClientCommands.lua: mutate server-side,
-- then syncBodyPart (broadcast) / transmitModData.
if isClient() then
    return
end

-- the client panel enforces 2 tiles and the patient must not move during
-- the action; latency can stretch the distance a little, so stay lenient
local MAX_DISTANCE_SQ = 36

local function handleTreatment(player, args, apply)
    local patient = getPlayerByOnlineID(args.id)
    if patient == nil or not patient:isAlive() then
        return
    end
    local parts = patient:getBodyDamage():getBodyParts()
    if args.part == nil or args.part < 0 or args.part >= parts:size() then
        return
    end
    local dx = player:getX() - patient:getX()
    local dy = player:getY() - patient:getY()
    if dx * dx + dy * dy > MAX_DISTANCE_SQ then
        return
    end
    apply(patient, parts:get(args.part))
end

local function onClientCommand(module, command, player, args)
    if module ~= "EmergencyMedical" or player == nil or args == nil then
        return
    end
    if command == "Cauterize" then
        handleTreatment(player, args, function(patient, part)
            if EMCauterize_IsEligiblePart(part) then
                EMTreatment_Cauterize(patient, part)
            end
        end)
    elseif command == "RemoveScab" then
        handleTreatment(player, args, function(patient, part)
            if EMRemoveScab_IsEligiblePart(patient, part) then
                EMTreatment_RemoveScab(patient, part)
            end
        end)
    elseif command == "DigBullet" then
        handleTreatment(player, args, function(patient, part)
            if part:haveBullet() then
                EMTreatment_DigBullet(patient, part)
            end
        end)
    elseif command == "RemovePatch" then
        handleTreatment(player, args, function(patient, part)
            if EM_Wound_Has(patient, part, "FentanylPatch") then
                EMTreatment_RemovePatch(patient, part)
            end
        end)
    elseif command == "CutBite" then
        handleTreatment(player, args, function(patient, part)
            if EMCutBite_IsEligiblePart(part) then
                EMTreatment_CutBite(patient, part, args.glass == true)
            end
        end)
    elseif command == "CrudeStitch" then
        handleTreatment(player, args, function(patient, part)
            if EMCrudeStitch_IsEligiblePart(patient, part) then
                EMTreatment_CrudeStitch(patient, part)
            end
        end)
    elseif command == "RemoveCrudeStitch" then
        handleTreatment(player, args, function(patient, part)
            if EMRemoveCrudeStitch_IsEligiblePart(patient, part) then
                EMTreatment_RemoveCrudeStitch(patient, part)
            end
        end)
    elseif command == "InfectWound" then
        handleTreatment(player, args, function(patient, part)
            EMTreatment_InfectWound(patient, part)
        end)
    elseif command == "TemporarySplint" then
        handleTreatment(player, args, function(patient, part)
            if EMTemporarySplint_IsEligiblePart(patient, part) then
                -- splintFactor comes from the acting doctor's skill, same
                -- formula as the vanilla splint; clamp what arrives
                local factor = tonumber(args.factor) or 1.0
                EMTreatment_TemporarySplint(patient, part, math.min(math.max(factor, 0.0), 5.5))
            end
        end)
    elseif command == "RemoveEmergencyFix" then
        handleTreatment(player, args, function(patient, part)
            if EM_Wound_Has(patient, part, "EmergencyFixed") then
                EMTreatment_RemoveEmergencyFix(patient, part)
            end
        end)
    elseif command == "TakeDrug" then
        -- self-use drug effect: the taker is the sender (consumption of
        -- the pill itself is vanilla client-side via JustTookPill ->
        -- UseAndSync). EMDrug_ApplyEffect dispatches only this mod's own
        -- six fullTypes -- that IS the validation.
        if type(args.drug) == "string" and player:isAlive() then
            EMDrug_ApplyEffect(player, args.drug)
        end
    end
end

Events.OnClientCommand.Add(onClientCommand)
