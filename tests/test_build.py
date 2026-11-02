import hashlib
import json
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import build


class PackagingTests(unittest.TestCase):
    def test_mod_only_contains_private_dependencies_and_no_loader(self):
        files = build.common_files()
        self.assertIn('PBZTrainingDummy/Scripts/vendor/UEHelpers.lua', files)
        self.assertIn('PBZTrainingDummy/Scripts/vendor/ModMenu.lua', files)
        self.assertIn('PBZTrainingDummy/config.ini', files)
        self.assertFalse(any(n.endswith('.dll') or '/shared/' in n or n.endswith('mods.txt') for n in files))
        self.assertFalse(any(n.startswith(('dev/', 'runtime/', 'backups/')) for n in files))
        for name, data in files.items():
            if name.endswith('.lua'):
                self.assertNotIn(b'D:/Applications/', data)
                self.assertNotIn(b'D:\\Game_mod', data)

    def test_wrong_runtime_archive_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            archive = Path(directory) / 'runtime.zip'
            archive.write_bytes(b'wrong archive')
            with self.assertRaisesRegex(ValueError, 'archive SHA256 mismatch'):
                build.runtime_files(archive, {'archive_sha256': '0' * 64})

    def test_archive_and_dll_are_both_verified(self):
        with tempfile.TemporaryDirectory() as directory:
            archive = Path(directory) / 'runtime.zip'
            with zipfile.ZipFile(archive, 'w') as z:
                for name in build.RUNTIME_FILES:
                    z.writestr(name, b'fixture')
            lock = {'archive_sha256': build.sha256(archive.read_bytes()), 'dll_sha256': '0' * 64}
            with self.assertRaisesRegex(ValueError, 'UE4SS.dll SHA256 mismatch'):
                build.runtime_files(archive, lock)
            lock['dll_sha256'] = build.sha256(b'fixture')
            files = build.runtime_files(archive, lock)
            self.assertEqual(files['ue4ss/Mods/mods.txt'], b'PBZTrainingDummy : 1\n')
            self.assertNotIn('ue4ss/Mods/mods.json', files)

    def test_zip_is_reproducible_and_manifest_covers_every_file(self):
        with tempfile.TemporaryDirectory() as directory:
            a, b = Path(directory) / 'a.zip', Path(directory) / 'b.zip'
            files = {'PBZTrainingDummy/config.ini': b'[Keybinds]\nMenuToggle=F8\n'}
            build.write_zip(a, files)
            build.write_zip(b, files)
            self.assertEqual(a.read_bytes(), b.read_bytes())
            with zipfile.ZipFile(a) as z:
                manifest = json.loads(z.read('package_manifest.json'))
                self.assertEqual(set(z.namelist()), set(manifest['files']) | {'package_manifest.json'})
                for name, digest in manifest['files'].items():
                    self.assertEqual(hashlib.sha256(z.read(name)).hexdigest(), digest)


if __name__ == '__main__':
    unittest.main()
