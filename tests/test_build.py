import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import build
import verify_packages


class PackagingTests(unittest.TestCase):
    def test_release_allowlist_excludes_scripts_and_local_files(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in build.common_files():
                target = root / name
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(b'fixture')
            for name in ('Check-Compatibility.ps1', 'PBZTrainingDummy/install.ps1',
                         'PBZTrainingDummy/Scripts/debug.py', 'PBZTrainingDummy/startup.log',
                         'README.md', 'THIRD_PARTY_NOTICES.md'):
                (root / name).write_bytes(b'must not ship')
            (root / 'docs').mkdir()
            (root / 'docs/COMPATIBILITY.md').write_bytes(b'must not ship')
            with patch.object(build, 'ROOT', root):
                files = build.common_files()
            self.assertFalse(any(n.endswith(('.ps1', '.py', '.log', '.md', '.doc', '.docx', '.pdf')) for n in files))
            self.assertEqual(set(files), {'PBZTrainingDummy/' + n for n in build.MOD_FILES} | {'LICENSE'})
            self.assertIn('PBZTrainingDummy/Scripts/main.lua', files)

    def test_mod_only_contains_private_dependencies_and_no_loader(self):
        files = build.common_files()
        self.assertIn('PBZTrainingDummy/Scripts/vendor/UEHelpers.lua', files)
        self.assertIn('PBZTrainingDummy/Scripts/vendor/ModMenu.lua', files)
        self.assertIn('PBZTrainingDummy/config.ini', files)
        self.assertIn('PBZTrainingDummy/Scripts/targets.lua', files)
        self.assertIn('PBZTrainingDummy/Scripts/practice.lua', files)
        self.assertIn('PBZTrainingDummy/Scripts/segments.lua', files)
        self.assertIn('PBZTrainingDummy/Scripts/i18n.lua', files)
        self.assertFalse(any('ui_language.txt' in name for name in files))
        self.assertFalse(any('dps_segments.json' in name for name in files))
        self.assertIn('PBZTrainingDummy/licenses/PhantomGladiator-MIT.txt', files)
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

    def test_zip_is_reproducible_and_contains_only_supplied_files(self):
        with tempfile.TemporaryDirectory() as directory:
            a, b = Path(directory) / 'a.zip', Path(directory) / 'b.zip'
            files = {'PBZTrainingDummy/config.ini': b'[Keybinds]\nMenuToggle=F8\n'}
            build.write_zip(a, files)
            build.write_zip(b, files)
            self.assertEqual(a.read_bytes(), b.read_bytes())
            with zipfile.ZipFile(a) as z:
                self.assertEqual(set(z.namelist()), set(files))
                for name, data in files.items():
                    self.assertEqual(z.read(name), data)

    def test_verifier_rejects_documentation_and_modified_runtime(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'pbz-damage-test-mod-only-windows-x64.zip'
            for unwanted in ('README.md', 'docs/COMPATIBILITY.md', 'install.ps1', 'package_manifest.json'):
                files = build.common_files()
                files[unwanted] = b'not a runtime dependency'
                build.write_zip(path, files)
                with self.assertRaisesRegex(AssertionError, 'Unexpected release files'):
                    verify_packages.verify(path)
            files = build.common_files()
            files['PBZTrainingDummy/Scripts/main.lua'] = b'modified'
            build.write_zip(path, files)
            with self.assertRaisesRegex(AssertionError, 'Source mismatch'):
                verify_packages.verify(path)


if __name__ == '__main__':
    unittest.main()
