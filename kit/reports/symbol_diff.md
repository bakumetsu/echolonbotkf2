# Symbol reconciliation (source vs doc)

Gate total (5 core files, labels excluded): **938** (doc: 943).

| File | function | event | state | const | var |
|---|---|---|---|---|---|
| KF2BotsMut.uc | 97 | 0 | 0 | 21 | **60** (doc 63) |
| KF2BotsFollowNavBase.uc | 36 | 5 | 2 | 0 | 97 |
| KF2BotBase.uc | 158 | 3 | 0 | 91 | **215** (doc 217) |
| KF2BotLogic.uc | 38 | 2 | 0 | 0 | 0 |
| KF2Bot.uc | 41 | 37 | 18 | 0 | 0 |

Reconciliation: 938 source - 22 `var()` vars the doc missed + 27 struct members the doc counted = **943** (doc 943). Unexplained differences: **0**.

## Differences (source wins)

| what | kind | name | source | note |
|---|---|---|---|---|
| source only | var | NumBots | Mut:44 | doc extractor missed `var()` declarations |
| source only | var | MinimumBots | Mut:45 | doc extractor missed `var()` declarations |
| source only | var | BotMinPerkLv | Mut:48 | doc extractor missed `var()` declarations |
| source only | var | BotMaxPerkLv | Mut:49 | doc extractor missed `var()` declarations |
| source only | var | BotsDamageScale | Mut:51 | doc extractor missed `var()` declarations |
| source only | var | ZedCountScaling | Mut:52 | doc extractor missed `var()` declarations |
| source only | var | bBotsUnlimitedAmmo | Mut:124 | doc extractor missed `var()` declarations |
| source only | var | bBotsUnlimitedCash | Mut:125 | doc extractor missed `var()` declarations |
| source only | var | bNoZerkerBots | Mut:127 | doc extractor missed `var()` declarations |
| source only | var | bUseCustomBotNames | Mut:128 | doc extractor missed `var()` declarations |
| source only | var | bShowBotLevel | Mut:129 | doc extractor missed `var()` declarations |
| source only | var | bShowBotRole | Mut:130 | doc extractor missed `var()` declarations |
| source only | var | CustomBotNames | Mut:131 | doc extractor missed `var()` declarations |
| source only | var | AllowedPerks | Mut:136 | doc extractor missed `var()` declarations |
| source only | var | MaxBotsPerPerk | Mut:137 | doc extractor missed `var()` declarations |
| source only | var | bDebugGrapple | Mut:139 | doc extractor missed `var()` declarations |
| source only | var | MaxZedsForFailsafe | Mut:140 | doc extractor missed `var()` declarations |
| source only | var | FailsafeActivationDelay | Mut:141 | doc extractor missed `var()` declarations |
| source only | var | HealCylinderRadius | Mut:143 | doc extractor missed `var()` declarations |
| source only | var | HealCylinderHeight | Mut:144 | doc extractor missed `var()` declarations |
| source only | var | HealMinHealthPct | Mut:145 | doc extractor missed `var()` declarations |
| source only | var | bEnableFastTraceHealing | Mut:146 | doc extractor missed `var()` declarations |
| doc only | var | Anchor | Mut:11 | doc counted a struct member as a class var |
| doc only | var | DeadOfficer | Mut:102 | doc counted a struct member as a class var |
| doc only | var | door | Base:6 | doc counted a struct member as a class var |
| doc only | var | ExpiresAt | Mut:20 | doc counted a struct member as a class var |
| doc only | var | GoalNav | Mut:31 | doc counted a struct member as a class var |
| doc only | var | GoalPoint | Mut:30 | doc counted a struct member as a class var |
| doc only | var | HumanPawn | Mut:114 | doc counted a struct member as a class var |
| doc only | var | Leader | Mut:10 | doc counted a struct member as a class var |
| doc only | var | Leader | Mut:28 | doc counted a struct member as a class var |
| doc only | var | Loc | Mut:115 | doc counted a struct member as a class var |
| doc only | var | Members | Mut:9 | doc counted a struct member as a class var |
| doc only | var | Node | Mut:18 | doc counted a struct member as a class var |
| doc only | var | NodeBlacklist | Mut:36 | doc counted a struct member as a class var |
| doc only | var | ObjectiveBailUntil | Mut:35 | doc counted a struct member as a class var |
| doc only | var | OldRank | Mut:104 | doc counted a struct member as a class var |
| doc only | var | Owner | Mut:19 | doc counted a struct member as a class var |
| doc only | var | Path | Base:7 | doc counted a struct member as a class var |
| doc only | var | Phase | Mut:33 | doc counted a struct member as a class var |
| doc only | var | Replacement | Mut:103 | doc counted a struct member as a class var |
| doc only | var | Score | Mut:105 | doc counted a struct member as a class var |
| doc only | var | SlotLocs | Mut:37 | doc counted a struct member as a class var |
| doc only | var | Slots | Mut:32 | doc counted a struct member as a class var |
| doc only | var | SquadID | Mut:27 | doc counted a struct member as a class var |
| doc only | var | SquadSeedAngle | Mut:38 | doc counted a struct member as a class var |
| doc only | var | StartTime | Mut:34 | doc counted a struct member as a class var |
| doc only | var | Vel | Mut:116 | doc counted a struct member as a class var |
| doc only | var | Zone | Mut:29 | doc counted a struct member as a class var |
