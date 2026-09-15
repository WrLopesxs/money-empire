"""Installer checks with isolated directories and simulated downloads; no native tools run."""
import hashlib
import importlib.util
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import zipfile

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location('empire_tools', ROOT / 'scripts/tools.py')
tools = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tools)


@unittest.skipUnless(os.name == 'nt', 'Windows batch integration tests')
class BatchInstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='Money Empire & setup ')
        self.root = Path(self.temp.name)
        (self.root / 'scripts').mkdir()
        shutil.copyfile(ROOT / 'Instalar.bat', self.root / 'Instalar.bat')
        (self.root / 'scripts/tools.py').write_text('# placeholder', encoding='utf-8')
        (self.root / 'scripts/install-python.cmd').write_text(
            '@echo off\necho python>>"%~dp0..\\calls.txt"\nexit /b %ME_TEST_PYTHON_EXIT%\n')
        (self.root / 'scripts/run-python.cmd').write_text(
            '@echo off\necho %~2 %~3>>"%~dp0..\\calls.txt"\n'
            'if "%~3"=="--studio" exit /b %ME_TEST_STUDIO_EXIT%\nexit /b 0\n')

    def tearDown(self):
        self.temp.cleanup()

    def invoke(self, *options, python_exit=0, studio_exit=0):
        env = os.environ.copy()
        env['ME_TEST_PYTHON_EXIT'] = str(python_exit)
        env['ME_TEST_STUDIO_EXIT'] = str(studio_exit)
        result = subprocess.run(
            ['cmd.exe', '/d', '/c', '.\\Instalar.bat', '--sem-pausa', *options],
            cwd=self.root, env=env, capture_output=True, text=True, timeout=15)
        log = self.root / 'calls.txt'
        calls = [line.strip() for line in log.read_text().splitlines()] if log.exists() else []
        return result, calls

    def test_complete_install_in_path_with_spaces_and_ampersand(self):
        result, calls = self.invoke()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(calls, ['python', 'setup', 'build', 'setup --studio'])

    def test_no_studio_option(self):
        result, calls = self.invoke('--sem-studio')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(calls, ['python', 'setup', 'build'])

    def test_python_failure_stops_installation(self):
        result, calls = self.invoke(python_exit=1)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(calls, ['python'])

    def test_studio_failure_reports_partial_installation(self):
        result, calls = self.invoke(studio_exit=1)
        self.assertEqual(result.returncode, 1)
        self.assertIn('INSTALACAO PARCIAL', result.stdout)
        self.assertEqual(calls, ['python', 'setup', 'build', 'setup --studio'])

    def test_unknown_option_does_not_install(self):
        result, calls = self.invoke('--invalid')
        self.assertEqual(result.returncode, 2)
        self.assertEqual(calls, [])

    def test_bootstrap_powershell_syntax(self):
        source = (ROOT / 'scripts/install-python.cmd').read_text(encoding='utf-8')
        command = source.split('powershell.exe -NoProfile -Command ^\n', 1)[1].split('\nexit /b', 1)[0].strip()[1:-1]
        env = os.environ.copy()
        env['ME_TEST_PARSE_SOURCE'] = command
        result = subprocess.run(['powershell.exe', '-NoProfile', '-Command',
            '$tokens=$null; $errors=$null; [void][System.Management.Automation.Language.Parser]::ParseInput($env:ME_TEST_PARSE_SOURCE,[ref]$tokens,[ref]$errors); if ($errors.Count) { $errors | Out-String | Write-Host; exit 1 }'],
            env=env, capture_output=True, text=True, timeout=15)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


class DownloadIntegrityTests(unittest.TestCase):
    def exercise(self, member, valid_hash=True):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / 'docs').mkdir()
            archive = root / 'fixture.zip'
            with zipfile.ZipFile(archive, 'w') as package:
                package.writestr(member, b'fixture-only-no-executable')
            digest = hashlib.sha256(archive.read_bytes()).hexdigest()
            with patch.object(tools, 'ROOT', root), patch.object(tools, 'TOOLS', root / '.tools'), \
                 patch.object(tools, 'PACKAGES', {'rojo': ('test', 'https://example.invalid/tool.zip')}), \
                 patch.object(tools, 'PACKAGE_HASHES', {'rojo': digest if valid_hash else '0' * 64}), \
                 patch.object(tools, 'download', side_effect=lambda url, path: shutil.copyfile(archive, path)):
                tools.setup()
                self.assertEqual((root / '.tools/rojo/rojo.exe').read_bytes(), b'fixture-only-no-executable')

    def test_verified_archive_extracts(self):
        self.exercise('rojo.exe')

    def test_corrupt_archive_is_rejected(self):
        with self.assertRaisesRegex(RuntimeError, 'Integridade invalida'):
            self.exercise('rojo.exe', valid_hash=False)

    def test_zip_path_escape_is_rejected(self):
        with self.assertRaisesRegex(RuntimeError, 'Caminho invalido'):
            self.exercise('../escape.exe')


if __name__ == '__main__':
    unittest.main(verbosity=2)
