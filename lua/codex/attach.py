"""Deliver this Neovim session's pending attachments to Codex at submission."""
import json
import os
from pathlib import Path
import sys


def main():
    sys.stdin.read()
    location = os.environ.get('NVIM_CODEX_CONTEXT')
    if not location:
        return
    pending = Path(location)
    claimed = Path(f'{pending}.{os.getpid()}')
    try:
        pending.rename(claimed)
    except FileNotFoundError:
        return
    try:
        snapshot = json.loads(claimed.read_text(encoding='utf-8'))
        print(json.dumps({'hookSpecificOutput': {
            'hookEventName': 'UserPromptSubmit',
            'additionalContext': snapshot['context'],
        }}), flush=True)
        receipt = Path(str(pending) + '.used')
        temporary = Path(str(receipt) + f'.{os.getpid()}')
        temporary.write_text(json.dumps(snapshot['revision']), encoding='utf-8')
        temporary.replace(receipt)
    finally:
        claimed.unlink(missing_ok=True)


if __name__ == '__main__':
    main()
