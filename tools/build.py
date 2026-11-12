"""Build both mod-only and pinned UE4SS packages, without executing native code."""
import argparse
import hashlib
import json
import re
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUNTIME_FILES = (
    'dwmapi.dll', 'ue4ss/UE4SS.dll', 'ue4ss/LICENSE',
    'ue4ss/MemberVariableLayout.ini', 'ue4ss/UE4SS_Signatures/GNatives.lua',
    'ue4ss/UE4SS_Signatures/GUObjectArray.lua', 'ue4ss/UE4SS_SDK_Backends/UE4SS.json',
)
MOD_FILES = (
    'config.ini', 'Scripts/main.lua', 'Scripts/runtime.lua', 'Scripts/adapter.lua',
    'Scripts/session.lua', 'Scripts/music.lua', 'Scripts/compat.lua', 'Scripts/config.lua',
    'Scripts/targets.lua', 'Scripts/practice.lua', 'Scripts/segments.lua', 'Scripts/i18n.lua', 'Scripts/owned.lua',
    'Scripts/vendor/ModMenu.lua', 'Scripts/vendor/UEHelpers.lua',
    'licenses/UE4SS-MIT.txt', 'licenses/ModMenu-MIT.txt',
    'licenses/PhantomGladiator-MIT.txt',
)


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def version():
    value = (ROOT / 'VERSION').read_text(encoding='utf-8').strip()
    if not re.fullmatch(r'\d+\.\d+\.\d+(?:-[a-zA-Z0-9.]+)?', value):
        raise ValueError('Invalid VERSION')
    return value


def common_files():
    files = {'PBZTrainingDummy/' + name: (ROOT / 'PBZTrainingDummy' / name).read_bytes()
             for name in MOD_FILES}
    files['LICENSE'] = (ROOT / 'LICENSE').read_bytes()
    return files


def runtime_files(archive, lock):
    archive = Path(archive)
    if sha256(archive.read_bytes()) != lock['archive_sha256']:
        raise ValueError('UE4SS archive SHA256 mismatch; refusing to package')
    with zipfile.ZipFile(archive) as z:
        files = {name: z.read(name) for name in RUNTIME_FILES}
    if sha256(files['ue4ss/UE4SS.dll']) != lock['dll_sha256']:
        raise ValueError('UE4SS.dll SHA256 mismatch')
    files['ue4ss/UE4SS-settings.ini'] = (ROOT / 'tools/UE4SS-settings.ini').read_bytes()
    files['ue4ss/Mods/mods.txt'] = b'PBZTrainingDummy : 1\n'
    return files


def write_zip(path, files):
    with zipfile.ZipFile(path, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for name, data in sorted(files.items()):
            info = zipfile.ZipInfo(name, date_time=(2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            z.writestr(info, data, compresslevel=9)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ue4ss-archive', type=Path, help='Use a local hash-verified upstream archive')
    parser.add_argument('--output', type=Path, default=ROOT / 'dist')
    args = parser.parse_args()
    lock = json.loads((ROOT / 'dependencies.json').read_text())['ue4ss']
    archive = args.ue4ss_archive
    if archive is None:
        archive = ROOT / '.cache' / 'ue4ss.zip'
        archive.parent.mkdir(parents=True, exist_ok=True)
        if not archive.exists():
            request = urllib.request.Request(lock['url'], headers={'User-Agent': 'pbz-damage-test-build'})
            with urllib.request.urlopen(request, timeout=90) as response:
                data = response.read()
            if sha256(data) != lock['archive_sha256']:
                raise ValueError('Downloaded UE4SS archive SHA256 mismatch')
            archive.write_bytes(data)
    runtime = runtime_files(archive, lock)
    common = common_files()
    args.output.mkdir(parents=True, exist_ok=True)
    outputs = []
    for variant in ('mod-only', 'with-UE4SS'):
        files = dict(common)
        if variant == 'with-UE4SS':
            files = {(('ue4ss/Mods/' + n) if n.startswith('PBZTrainingDummy/') else n): b
                     for n, b in files.items()}
            files.update(runtime)
        path = args.output / f'pbz-damage-test-v{version()}-{variant}-windows-x64.zip'
        write_zip(path, files)
        outputs.append(path)
        print(f'Built {path.name} ({path.stat().st_size} bytes)')
    checksum = ''.join(f'{sha256(p.read_bytes())}  {p.name}\n' for p in outputs)
    (args.output / 'SHA256SUMS.txt').write_text(checksum, encoding='utf-8', newline='\n')


if __name__ == '__main__':
    main()
