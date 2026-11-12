"""Optional Lua 5.4 checks using an explicitly installed lupa.lua54; no game required."""
from pathlib import Path
from lupa.lua54 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


def main():
    syntax = LuaRuntime(unpack_returned_tuples=True)
    assert syntax.eval('_VERSION') == 'Lua 5.4'
    check = syntax.eval('function(path) local f,e=loadfile(path); assert(f,e) end')
    sources = sorted((ROOT / 'PBZTrainingDummy').rglob('*.lua'))
    for source in sources:
        check(source.as_posix())
    tests = sorted((ROOT / 'tests').glob('*_test.lua'))
    for test in tests:
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.globals().arg = lua.table_from({1: ROOT.as_posix()})
        print(f'Running {test.name}', flush=True)
        lua.execute(test.read_text(encoding='utf-8'), name=test.as_posix())
    print(f'Lua 5.4: {len(sources)} sources parsed, {len(tests)} behavior suites passed')


if __name__ == '__main__':
    main()
