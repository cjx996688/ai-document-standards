"""Exercise real installers in temporary directories, without live network calls."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
START = '<!-- WORD_STANDARD_START -->'
END = '<!-- WORD_STANDARD_END -->'


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='word-standard-test-')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.config = self.base / 'config with spaces'
        self.config.mkdir()
        self.agents = self.config / 'AGENTS.md'
        if os.name == 'nt':
            self.runner = shutil.which('powershell.exe')
        else:
            self.runner = shutil.which('bash')
        if not self.runner:
            self.skipTest('No platform installer interpreter available')

    def install(self, offline=False):
        if os.name == 'nt':
            quote = lambda value: "'" + str(value).replace("'", "''") + "'"
            call = '& ' + quote(ROOT / 'setup_codex_word_standard.ps1')
            call += ' -ConfigDirectory ' + quote(self.config)
            if offline:
                # Shadow only the download cmdlet within this child process.
                call = "function Invoke-WebRequest { throw 'Simulated network failure' }; " + call
            else:
                call += ' -UseLocalStandard'
            command = [self.runner, '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-Command', call]
            env = None
        else:
            command = [self.runner, str(ROOT / 'setup_codex_word_standard.sh'), '--config-dir', str(self.config)]
            env = os.environ.copy()
            if offline:
                mockbin = self.base / 'bin'
                mockbin.mkdir(exist_ok=True)
                mock = mockbin / 'curl'
                mock.write_text('#!/bin/sh\nexit 7\n')
                mock.chmod(0o755)
                env['PATH'] = str(mockbin) + os.pathsep + env['PATH']
            else:
                command.append('--local')
        return subprocess.run(command, env=env, capture_output=True, timeout=20)

    def assert_success(self, result):
        self.assertEqual(result.returncode, 0, (result.stdout + result.stderr).decode(errors='replace'))

    def test_first_install_and_idempotence(self):
        self.assert_success(self.install())
        text = self.agents.read_text(encoding='utf-8')
        self.assertEqual(text.count(START), 1)
        self.assertIn('默认后台生成', text)
        self.assertEqual((self.config / 'word_format.md').read_bytes(), (ROOT / 'word_format.md').read_bytes())
        first = self.agents.read_bytes()
        self.assert_success(self.install())
        self.assertEqual(self.agents.read_bytes(), first)
        self.assertEqual(list(self.config.glob('AGENTS.md.bak.*')), [])

    def test_upgrade_preserves_other_instructions_and_backup(self):
        old = f'Before rules\n{START}\nOld expensive rules\n{END}\nAfter rules\n'
        self.agents.write_text(old, encoding='utf-8')
        original = self.agents.read_bytes()
        self.assert_success(self.install())
        new = self.agents.read_text(encoding='utf-8')
        self.assertTrue(new.startswith('Before rules\n'))
        self.assertTrue(new.endswith('After rules\n'))
        self.assertNotIn('Old expensive rules', new)
        self.assertIn('默认后台生成', new)
        backups = list(self.config.glob('AGENTS.md.bak.*'))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_bytes(), original)
        self.assert_success(self.install())
        self.assertEqual(len(list(self.config.glob('AGENTS.md.bak.*'))), 1)

    def test_append_preserves_unmanaged_text(self):
        self.agents.write_text('Unrelated instructions\n', encoding='utf-8')
        self.assert_success(self.install())
        self.assertTrue(self.agents.read_text(encoding='utf-8').startswith('Unrelated instructions\n'))

    def test_malformed_markers_do_not_change_agents(self):
        cases = [START, END, END + '\n' + START,
                 f'{START}\nx\n{END}\n{START}\ny\n{END}',
                 f'prefix {START}\nx\n{END}']
        for old in cases:
            with self.subTest(markers=old):
                self.agents.write_text(old, encoding='utf-8')
                original = self.agents.read_bytes()
                self.assertNotEqual(self.install().returncode, 0)
                self.assertEqual(self.agents.read_bytes(), original)

    def test_offline_fallback(self):
        # No cache: repository copy; existing cache: retain it.
        self.assert_success(self.install(offline=True))
        cache = self.config / 'word_format.md'
        self.assertEqual(cache.read_bytes(), (ROOT / 'word_format.md').read_bytes())
        cache.write_text('Existing cached standard\n', encoding='utf-8')
        self.assert_success(self.install(offline=True))
        self.assertEqual(cache.read_text(encoding='utf-8'), 'Existing cached standard\n')


if __name__ == '__main__':
    unittest.main()
