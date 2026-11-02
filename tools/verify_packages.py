"""Check package hashes, ownership boundaries and pinned runtime identity."""
import argparse
import json
import zipfile
from pathlib import Path
from build import ROOT, sha256


def verify(path):
    lock = json.loads((ROOT / 'dependencies.json').read_text())['ue4ss']
    bundled = '-with-UE4SS-' in path.name
    prefix = 'ue4ss/Mods/' if bundled else ''
    with zipfile.ZipFile(path) as z:
        names = z.namelist()
        assert len(names) == len(set(names)), 'Duplicate ZIP entries'
        assert all(not n.startswith('/') and '..' not in Path(n).parts and '\\' not in n for n in names)
        manifest = json.loads(z.read('package_manifest.json'))
        assert set(names) == set(manifest['files']) | {'package_manifest.json'}
        for name, digest in manifest['files'].items():
            assert sha256(z.read(name)) == digest, f'Checksum mismatch: {name}'
        for name in ('main.lua', 'runtime.lua', 'adapter.lua', 'session.lua', 'music.lua',
                     'compat.lua', 'config.lua', 'vendor/ModMenu.lua', 'vendor/UEHelpers.lua'):
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
    for line in (args.directory / 'SHA256SUMS.txt').read_text().splitlines():
        digest, name = line.split('  ', 1)
        assert Path(name).name == name
        assert sha256((args.directory / name).read_bytes()) == digest


if __name__ == '__main__':
    main()
