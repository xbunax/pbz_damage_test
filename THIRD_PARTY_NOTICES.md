# Third-party notices

## ue4ss-ModMenu

- Author/copyright: Matthew arvidson, 2026.
- Source: https://github.com/mattdavida/ue4ss-ModMenu
- Pinned source commit: `aff9716695f5432441cb329a9615721cc26a0d57`.
- Included as `PBZTrainingDummy/Scripts/vendor/ModMenu.lua` (generated upstream bundle).
- Local changes: Chinese keyboard hint, removal of the dock picker, private module namespace, and private UEHelpers import.
- License: MIT; full text in `PBZTrainingDummy/licenses/ModMenu-MIT.txt`.

## UE4SS / UEHelpers

- UE4SS copyright: Narknon, 2022, and contributors.
- PBZ runtime distribution: https://github.com/KintaroModding/ue4ss
- Version: `v3.0.1-1183-gcdbc0b66`; archive and DLL identity in `docs/COMPATIBILITY.md` and the source repository's `dependencies.json`.
- `PBZTrainingDummy/Scripts/vendor/UEHelpers.lua` is copied from that archive's `ue4ss/Mods/shared/UEHelpers/UEHelpers.lua`, unmodified.
- License: MIT; full text in `PBZTrainingDummy/licenses/UE4SS-MIT.txt`.
- The with-UE4SS package additionally redistributes the hash-verified upstream proxy, runtime DLL, signatures, member layout, SDK backend and license. Runtime settings are the project's tested configuration; default upstream example mods are omitted.

Game assets are loaded from the user's installed game and are not included in this repository or release packages.
