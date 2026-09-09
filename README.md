# Emergency Medicine

A medical and drug expansion for Project Zomboid (Build 42). It adds field-expedient trauma care, nine real-world drugs, and a full addiction and withdrawal simulation on top of the vanilla health system.

Every gameplay value is configurable through the sandbox settings (tabs: Emergency Medicine - General / Drugs / Spawns).

## New items

Drugs, found in hospitals, pharmacies, police evidence, army medical crates and farms:

- **Morphine** - injectable. Instantly restores health, full painkiller effect, clears the mind. Highly addictive.
- **Fentanyl** - injectable. Restores health and erases every wound on the body, including previously treated wounds. Extremely addictive.
- **OxyContin** - pill bottle (20 doses). Restores some health, halves boredom, unhappiness and panic, eases withdrawal.
- **Sufentanil** - patch applied to the right upper arm. Days of sustained pain relief and withdrawal easing, with a quietly growing addiction.
- **Naloxone** - opioid antagonist. Reduces addiction at the cost of hunger and thirst.
- **Tranexamic acid** - stops all bleeding instantly. Side effect: head pain.
- **Sulfadimidine** - antibiotic. Clears wound infections (not the zombie virus). Side effects: head pain and fever.
- **Dexmedetomidine** - veterinary sedative. Wipes panic and stress, causes drowsiness.
- **Methamphetamine** - stimulant. Instantly removes fatigue and starts an addiction ramp; the withdrawal that follows is long and brutal.

Medical gear:

- **Grass bandage** - crafted from 10 grass tufts. Works as a weak bandage and almost always infects the wound.
- **Book splint** - crafted from 2 books and 2 rags. Produces a vanilla splint.
- **Improvised splint** - crafted from a stick, handle, bar, pipe, branch, book, magazine, newspaper or welding rod, plus tape, wire or a rag.

## New mechanics

### Wound treatment

All treatments are right-click actions on body parts in the health panel, and work on other players as well as on yourself.

- **Cauterize** (lighter or gunpowder): burns the wound shut. The wound disappears and leaves a long-lived scab that aches constantly; a new wound on the same part pops the old one back out. A scalpel scrapes the scab off, its severity depending on the scab's age.
- **Crude stitch** (glue or stapler): closes a deep wound. Every wound on the part hurts more while the stitching holds. A scalpel excision reopens it according to its age, and a fresh deep wound tears it open early.
- **Dig bullet** (bare hands): the risky alternative to tweezers. Always leaves a deep wound, bleeding and a wound infection.
- **Excise bite** (knife or broken glass): removes a fresh bite before the virus can establish itself. Broken glass leaves shards in the wound.
- **Improvised fixation** (improvised splint): takes a fracture out of the body for about a year - no fracture line, no limp, no fracture damage - while every wound on the limb hurts more. Tearing the fixation off brings the bone back worse the longer it was worn; wearing it the full year heals the fracture outright.

Injuries that match a treated wound bring the stored wound back, with severities stacking.

### Addiction and withdrawal

- Opioids share one addiction and withdrawal pair. Every injection raises the baseline; withdrawal builds toward it and only full cold turkey burns the baseline back down. Withdrawal dims the screen and grows the longer it goes untreated.
- Amphetamine has its own pair with body effects: mild and moderate withdrawal suppress hunger and fatigue and steadily restore endurance; severe withdrawal brings drunkenness, panic, unhappiness and a ravenous appetite.
- Opioid and amphetamine withdrawal together drain health until death.

### Display

Treated wounds show as their own lines on the health panel, and custom status icons for addiction and withdrawal render in the vanilla moodle column.

## Multiplayer

All treatments and drug effects run server-authoritative, matching Build 42's server-side body damage and player data.