-- EmergencyMedical: official Build 42 registry identifiers.
-- The game runs this file (ModRegistries.init) before all other Lua files
-- and scripts, and re-runs it after every registry reset (Lua reload /
-- return to main menu), so the stored references always stay current.
-- Only registry register calls belong in this file.
EM = EM or {}
EM.MoodleTypes = {}
EM.MoodleTypes.OpioidAddiction = MoodleType.register("EmergencyMedical:OpioidAddiction")
EM.MoodleTypes.OpioidWithdrawal = MoodleType.register("EmergencyMedical:OpioidWithdrawal")
