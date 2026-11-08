"""Check package hashes, ownership boundaries and pinned runtime identity."""
import argparse
import json
import zipfile
from pathlib import Path
from build import ROOT, RUNTIME_FILES, common_files, sha256


def verify(path):
    lock = json.loads((ROOT / 'dependencies.json').read_text())['ue4ss']
    bundled = '-with-UE4SS-' in path.name
    prefix = 'ue4ss/Mods/' if bundled else ''
    with zipfile.ZipFile(path) as z:
        names = z.namelist()
        expected = {(prefix + n if n.startswith('PBZTrainingDummy/') else n)
                    for n in common_files()}
        if bundled:
            expected.update(RUNTIME_FILES)
            expected.update(('ue4ss/UE4SS-settings.ini', 'ue4ss/Mods/mods.txt'))
        assert set(names) == expected, 'Unexpected release files'
        assert not any(Path(n).suffix.lower() in ('.ps1', '.bat', '.cmd', '.py', '.exe', '.zip', '.pdb',
                       '.md', '.rst', '.doc', '.docx', '.pdf', '.html', '.rtf')
                       for n in names), 'Documentation, maintenance scripts and build files must not ship'
        assert len(names) == len(set(names)), 'Duplicate ZIP entries'
        assert all(not n.startswith('/') and '..' not in Path(n).parts and '\\' not in n for n in names)
        for name, data in common_files().items():
            entry = prefix + name if name.startswith('PBZTrainingDummy/') else name
            assert z.read(entry) == data, f'Source mismatch: {entry}'
        for name in ('main.lua', 'runtime.lua', 'adapter.lua', 'session.lua', 'music.lua',
                     'compat.lua', 'config.lua', 'targets.lua', 'practice.lua', 'segments.lua', 'i18n.lua', 'vendor/ModMenu.lua', 'vendor/UEHelpers.lua'):
            assert prefix + 'PBZTrainingDummy/Scripts/' + name in names
        assert prefix + 'PBZTrainingDummy/config.ini' in names
        assert not any('/shared/' in n or '/UnifiedHitstop/' in n for n in names)
        assert not any(n.startswith(('dev/', 'backups/', 'runtime/', 'SaveGames/')) for n in names)
        if bundled:
            assert sha256(z.read('ue4ss/UE4SS.dll')) == lock['dll_sha256']
            assert z.read('ue4ss/Mods/mods.txt') == b'PBZTrainingDummy : 1\n'
            assert 'dwmapi.dll' in names
        else:
            assert not any(n.lower().endswith('.dll') for n in names), 'mod-only must not ship a loader'
            assert not any(n.startswith('ue4ss/') or n.endswith('mods.txt') for n in names)
    print(f'PASS package: {path.name}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory', nargs='?', type=Path, default=ROOT / 'dist')
    args = parser.parse_args()
    packages = sorted(args.directory.glob('*.zip'))
    assert len(packages) == 2, 'Expected exactly two release packages'
    for path in packages:
        verify(path)
    checksums = (args.directory / 'SHA256SUMS.txt').read_text().splitlines()
    assert len(checksums) == len(packages), 'Expected one checksum per release package'
    checked = set()
    for line in checksums:
        digest, name = line.split('  ', 1)
        assert Path(name).name == name and name not in checked
        assert sha256((args.directory / name).read_bytes()) == digest
        checked.add(name)
    assert checked == {p.name for p in packages}, 'Checksum list does not match release packages'


if __name__ == '__main__':
    main()
