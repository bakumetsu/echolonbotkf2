from uc_lexer import NAME, STRING, tokenize
from uc_parser import parse_file
from common import read_lines


def test_literals_and_comments():
    toks = tokenize("x = 'Foo' $ \"a // b\"; // c\n/* d\n e */ y;")
    assert [t.kind for t in toks if t.kind in (NAME, STRING)] == [NAME, STRING]
    assert toks[-2].text == "y" and toks[-2].line == 3


def test_parser_decls():
    src = """class A extends Actor config(X);
var() config byte NumBots;
var int B, C<UIMin=0>;
const K = 3;
struct S { var int M; };
enum E { E_One, E_Two };
simulated function int F(out int P, optional float Q) { local int L; return 1; }
state Idle extends Base
{
    ignores Bump;
    event BeginState(Name Prev) {}
Begin:
    Sleep(1.0);
    goto('Begin');
}
defaultproperties
{
    NumBots=7
}
"""
    pf = parse_file(src)
    kinds = [(d.kind, d.name) for d in pf.decls]
    assert ("var", "NumBots") in kinds and ("var", "B") in kinds and ("var", "C") in kinds
    assert ("member", "M") in kinds and ("enum", "E") in kinds and ("const", "K") in kinds
    f = next(d for d in pf.decls if d.name == "F")
    assert f.return_type == "int" and [p.name for p in f.params] == ["P", "Q"] and f.params[0].mods == ["out"]
    st = next(d for d in pf.decls if d.kind == "state")
    assert st.parent == "Base" and st.ignores == ["Bump"] and st.label_code
    assert next(d for d in pf.decls if d.name == "BeginState").state == "Idle"
    assert "editable" in next(d for d in pf.decls if d.name == "NumBots").mods


def test_read_lines_counts_like_readalllines(tmp_path):
    p = tmp_path / "x.uc"
    p.write_bytes(b"a\r\nb\r\nc")
    assert read_lines(p) == ["a", "b", "c"]
    p.write_bytes(b"a\nb\n")
    assert read_lines(p) == ["a", "b"]
