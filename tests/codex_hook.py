"""Check attachment delivery without making a model request."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

HOOK = Path(__file__).resolve().parents[1] / 'lua/codex/attach.py'


class AttachmentHookTests(unittest.TestCase):
    def test_consumes_snapshot_once_and_acknowledges_revision(self):
        with tempfile.TemporaryDirectory() as directory:
            pending = Path(directory) / 'pending.json'
            pending.write_text(json.dumps({'revision': 7, 'context': 'file.lua · lines 2–4\nunsaved text'}))
            env = dict(os.environ, NVIM_CODEX_CONTEXT=str(pending))
            result = subprocess.run(['python3', str(HOOK)], input='{"prompt":"Explain this"}',
                                    text=True, capture_output=True, env=env, check=True)
            output = json.loads(result.stdout)['hookSpecificOutput']
            self.assertEqual(output['hookEventName'], 'UserPromptSubmit')
            self.assertIn('unsaved text', output['additionalContext'])
            self.assertEqual(json.loads(Path(str(pending) + '.used').read_text()), 7)
            self.assertFalse(pending.exists())
            again = subprocess.run(['python3', str(HOOK)], input='{}', text=True,
                                   capture_output=True, env=env, check=True)
            self.assertEqual(again.stdout, '')

    def test_no_bridge_does_nothing(self):
        env = dict(os.environ)
        env.pop('NVIM_CODEX_CONTEXT', None)
        result = subprocess.run(['python3', str(HOOK)], input='{}', text=True,
                                capture_output=True, env=env, check=True)
        self.assertEqual(result.stdout, '')


if __name__ == '__main__':
    unittest.main()
