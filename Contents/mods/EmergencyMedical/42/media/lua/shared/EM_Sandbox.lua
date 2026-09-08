-- EmergencyMedical: runtime access to the mod's sandbox options
-- (defined in media/sandbox-options.txt, shown on the "急诊医疗" page of
-- the sandbox settings). Consumers read values AT RUNTIME through
-- EM_Sandbox_Get -- never cache them at file load time, the sandbox
-- values are only final once a game is loaded.
--
-- The mirrored defaults below MUST match sandbox-options.txt; they kick
-- in whenever the option table is absent (main menu lua, or a save made
-- before an option existed).
--
-- Unit notes:
-- * WithdrawalFallRate / AddictionDecayRate are FRACTIONS OF THE FULL
--   VALUE PER GAME DAY (0-1); the simulation converts them to the
--   original per-minute decimals by dividing by 1440.

local DEFAULTS = {
	CauterizePain = 35,
	CauterizeDamage = 5,
	ScabDurationDays = 90,
	ScabPainFloor = 15,
	RemoveScabPain = 10,
	ScabScratchSevere = 18,
	ScabScratchModerate = 15,
	ScabScratchLight = 8,
	ScabScratchOld = 3,
	DigBulletPain = 20,
	DigBulletSeverity = 10,
	DigBulletBleeding = 5,
	DigBulletInfection = 3,
	CrudeStitchedDurationDays = 120,
	CrudeStitchPainBoost = 0.2,
	RemoveCrudeStitchPain = 100,
	CrudeStitchReopenSevere = 18,
	CrudeStitchReopenModerate = 15,
	CrudeStitchReopenLight = 8,
	CrudeStitchReopenOld = 3,
	EmergencyFixDurationDays = 365,
	EmergencyFixPainBoost = 0.45,
	EmergencyFixWorsenPerDay = 0.01,
	MorphineAddictionGain = 0.5,
	InjectionRelief = 0.35,
	WithdrawalClimbMinutes = 180,
	WithdrawalFallRate = 0.288,
	AddictionDecayRate = 0.72,
	AmphWithdrawalClimbMinutes = 1440,
	AmphDecayRate = 0.36,
	AmphPanicPerMinute = 0.01,
	AmphUnhappinessPerMinute = 0.01,
	AmphDrunkPerMinute = 0.02,
	AmphSleepReductionPerMinute = 0.01,
	AmphHungerSuppressionPerMinute = 0.01,
	AmphEnduranceRestorePerMinute = 0.01,
	AmphCrashAppetitePerDay = 1.0,
	CrossWithdrawalHealthLoss = 0.1,
	FentanylAddiction = 1.0,
	FentanylRelief = 1.0,
	OxycontinAddiction = 0.15,
	OxycontinRelief = 0.2,
	NaloxoneAddictionReduce = 0.25,
	NaloxoneHungerThirst = 0.25,
	HazeMaxAlpha = 0.87,
	SufentanilPatchDays = 3,
	SufentanilPainkillerPerMinute = 0.05,
	SufentanilWithdrawalRelief = 0.05,
	SufentanilAddictionPerMinute = 0.01,
	SufentanilClearMind = true,
	DrugStatusDoseGain = 0.2,
	DrugStatusDecayPerHour = 0.05,
	DrugStatusDebuffRate = 1.0,
}

function EM_Sandbox_Get(name)
	if SandboxVars ~= nil and SandboxVars.EmergencyMedical ~= nil then
		local value = SandboxVars.EmergencyMedical[name]
		if value ~= nil then
			return value
		end
	end
	return DEFAULTS[name]
end
