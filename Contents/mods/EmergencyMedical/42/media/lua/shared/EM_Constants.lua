-- EmergencyMedical: cross-file gameplay constants. Numbers that are
-- deliberate design decisions and deliberately NOT sandbox-exposed (see
-- EM_Sandbox.lua for the configurable ones). Rule of thumb: a constant
-- used by a single file stays at the top of that file; anything shared
-- by more than one file lives here. Referenced at runtime everywhere,
-- so load order never matters.
EM_CONST = {
    -- game-time denominations: hoursSurvived is denominated in game
    -- hours; wound states store their timestamps in it, treatments
    -- convert elapsed time to days with this, and per-day sandbox rates
    -- convert to per-minute with MINUTES_PER_GAME_DAY
    HOURS_PER_GAME_DAY = 24.0,
    MINUTES_PER_GAME_DAY = 1440.0,

    -- the character's overall health scale tops at 100
    HEALTH_MAX = 100.0,

    -- the part's additionalPain runs 0..100 (vanilla pain semantics:
    -- the health panel shows the pain line above 10)
    PAIN_MAX = 100.0,

    -- wound/fracture/bleeding heal-time fields run 0..100 (panel shows
    -- a fracture as "Severe" past 50)
    WOUND_TIME_MAX = 100.0,

    -- CharacterStats measured on a 0..1 scale (DRUNK, FATIGUE, HUNGER,
    -- THIRST, STRESS, the stored painkiller dose ...)
    STAT_SCALE_MAX = 1.0,

    -- CharacterStats measured on a 0..100 scale (PANIC, UNHAPPINESS,
    -- BOREDOM ...)
    STAT_SCALE_MAX_100 = 100.0,
}
