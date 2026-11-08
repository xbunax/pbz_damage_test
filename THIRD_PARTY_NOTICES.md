# Third-party notices

## ue4ss-ModMenu

- Author/copyright: Matthew arvidson, 2026.
- Source: https://github.com/mattdavida/ue4ss-ModMenu
- Pinned source commit: `aff9716695f5432441cb329a9615721cc26a0d57`.
- Included as `PBZTrainingDummy/Scripts/vendor/ModMenu.lua` (generated upstream bundle).
- Local changes: configurable localized keyboard hint, removal of the dock picker, private module namespace, and private UEHelpers import.
- License: MIT; full text in `PBZTrainingDummy/licenses/ModMenu-MIT.txt`.

## UE4SS / UEHelpers

- UE4SS copyright: Narknon, 2022, and contributors.
- PBZ runtime distribution: https://github.com/KintaroModding/ue4ss
- Version: `v3.0.1-1183-gcdbc0b66`; archive and DLL identity in `docs/COMPATIBILITY.md` and the source repository's `dependencies.json`.
- `PBZTrainingDummy/Scripts/vendor/UEHelpers.lua` is copied from that archive's `ue4ss/Mods/shared/UEHelpers/UEHelpers.lua`, unmodified.
- License: MIT; full text in `PBZTrainingDummy/licenses/UE4SS-MIT.txt`.
- The with-UE4SS package additionally redistributes the hash-verified upstream proxy, runtime DLL, signatures, member layout, SDK backend and license. Runtime settings are the project's tested configuration; default upstream example mods are omitted.

## PhantomGladiator catalog reference

- Source: https://github.com/LingYi-Liang/PhantomGladiator
- Pinned reference commit: `5a8008753063af0b82ab2fe6193789e2a16715ec`.
- Author/copyright: LingYi-Liang, 2026.
- The target whitelist cross-checks class paths, names, native codex enemy types and boss flags against its exported catalog. Its application and gameplay modules are not bundled or executed by this mod.
- License: MIT; full text in `PBZTrainingDummy/licenses/PhantomGladiator-MIT.txt`.
- Chinese category captions explain the game's internal enum values; they are not asserted to be verified official localized labels.

Game assets are loaded from the user's installed game and are not included in this repository or release packages.
