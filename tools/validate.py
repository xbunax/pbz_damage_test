"""Compile-check Lua sources and run engine-independent behavior tests."""
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    compiler = shutil.which('luac5.4') or shutil.which('luac')
    interpreter = shutil.which('lua5.4') or shutil.which('lua')
    if not compiler or not interpreter:
        raise SystemExit('Lua 5.4 and luac are required (Ubuntu: sudo apt-get install lua5.4)')
    subprocess.run([interpreter, '-e', 'assert(_VERSION=="Lua 5.4", "Lua 5.4 required")'], check=True)
    for source in sorted((ROOT / 'PBZTrainingDummy').rglob('*.lua')):
        subprocess.run([compiler, '-p', str(source)], check=True)
    for test in sorted((ROOT / 'tests').glob('*_test.lua')):
        subprocess.run([interpreter, str(test), ROOT.as_posix()], check=True)
    print('Lua compilation and behavior tests passed')


if __name__ == '__main__':
    main()
