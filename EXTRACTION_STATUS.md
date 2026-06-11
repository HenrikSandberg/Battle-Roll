# Army extraction progress

Source PDFs: `/Users/henrik/Downloads/armies/`. Target: `Battle Roll/Resources/Data/Armies/*.json` (schema reference: `KhainiteShadowCoven.json`).

Method per army: pypdf text dump for ability wording + `pdftoppm -png -r 200` renders to verify stat hexes (Move/Health/Save/Control), keywords, and timing labels (text extraction interleaves them). Condensed functional descriptions, no flavour text.

## Done
- [x] Daughters of Khaine Khainite Shadow Coven.pdf → KhainiteShadowCoven.json
- [x] Stormcast Eternals Yndrasta's.pdf (p1–8) → YndrastasSpearhead.json
- [x] Stormcast Eternals Yndrasta's.pdf (p9–15) → VigilantBrotherhood.json (same PDF, 2 armies!)
- [x] Sylvaneth Spitewing Flight .pdf → SpitewingFlight.json
- [x] Slaves to Darkness Bloodwind Legion.pdf → BloodwindLegion.json
- [x] Nighthaunt Slasher Host.pdf → SlasherHost.json

## Remaining (one army per PDF unless noted)
- [ ] Blades of Khorne Bloodbound Gore Pilgrims.pdf
- [ ] Blades of Khorne Fangs of the Blood God.pdf
- [ ] Cities of Sigmar Castelite Company.pdf
- [ ] Cities of Sigmar Fusil Platoon.pdf
- [ ] Daughters of Khaine Heartflayer Troupe.pdf
- [ ] Disciples of Tzeentch Fluxblade Coven.pdf
- [ ] Disciples of Tzeentch.pdf (identify army inside)
- [ ] Flesh Eater Courts Carrion Retainers.pdf
- [ ] Flesh Eater Courts Charnel Watch.pdf
- [ ] Gloomspite Gitz Bad Moon Madmob.pdf
- [ ] Gloomspite Gitz Snarlpack Hunters.pdf
- [ ] Hedonites of Slaanesh Blades of the Lurid Dream.pdf
- [ ] Helsmiths of Hashut Helforge Host.pdf
- [ ] Idoneth Deepkin Akhelian Tide Guard.pdf
- [ ] Idoneth Deepkin Soulraid Hunt.pdf
- [ ] Kharadron Overlords Grundstok Trailblazers.pdf
- [ ] Kharadron Overlords Skyhammer Task Force.pdf
- [ ] Lumineth Realmlords Glittering Phalanx.pdf
- [ ] Lumineth Realmlords.pdf (identify army inside)
- [ ] Maggotkin of Nurgle Bleak Host.pdf
- [ ] Maggotkin of Nurgle Bubonic Cell.pdf
- [ ] Nighthaunt Cursed Shacklehorde.pdf
- [ ] Nighthaunt Slasher Host.pdf
- [ ] Ogor Mawtribes Scrapglutt.pdf
- [ ] Orruk Warclans Ironjawz Bigmob.pdf
- [ ] Ossiarch Bonereapers Kavalos Vanguard.pdf
- [ ] Ossiarch Bonereapers Mortisan Elite.pdf
- [ ] Seraphon Sunblooded Prowlers.pdf
- [ ] Skaven Gnawfeast Clawpack.pdf
- [ ] Slaves to Darkness Bloodwind Legion.pdf
- [ ] Slaves to Darkness Darkoath Raiders.pdf
- [ ] Soulblight Gravelords Bloodcrave Hunt.pdf
- [ ] Soulblight Gravelords Deathrattle Tomb Host.pdf
- [ ] Swampskulka Gang Orruk Warclans.pdf
- [ ] Sylvaneth Spitewing Flight .pdf

After all done: delete this file, rebuild, verify count in app, commit.
