"""UnrealScript (UE3 / KF2) tokenizer shared by the indexer, slicer and validator.

Comments are dropped (but kept as a side list), strings and 'name' literals are single tokens,
backtick macros (`log(...)) are one MACRO token, #exec lines are one DIRECTIVE token.
Every token carries its 1-based line. Line numbers match common.read_lines().
"""
from __future__ import annotations

from dataclasses import dataclass

IDENT, NUMBER, STRING, NAME, PUNCT, MACRO, DIRECTIVE = (
    "ident", "number", "string", "name", "punct", "macro", "directive")

# Longest first so ">>>=" wins over ">>".
_OPS = sorted("""
>>>= >>> <<= >>= == != <= >= && || ^^ ++ -- += -= *= /= @= $= ~= << >> ** -> :: ~=
{ } ( ) [ ] ; , . : ? ! ~ + - * / % & | ^ = < > @ $ #
""".split(), key=len, reverse=True)


@dataclass(slots=True)
class Token:
    kind: str
    text: str
    line: int
    col: int

    @property
    def low(self) -> str:
        return self.text.lower()

    def is_(self, *words: str) -> bool:
        return self.kind == IDENT and self.text.lower() in words

    def __repr__(self) -> str:  # compact in test failures
        return f"{self.kind}:{self.text!r}@{self.line}"


class LexError(Exception):
    pass


def tokenize(text: str, keep_comments: list | None = None) -> list[Token]:
    """Tokenize normalised (\\n-only) text. Comments go to keep_comments as (line, text)."""
    toks: list[Token] = []
    i, n, line, line_start = 0, len(text), 1, 0
    while i < n:
        c = text[i]
        if c == "\n":
            line += 1
            i += 1
            line_start = i
            continue
        if c in " \t\r\f\v":
            i += 1
            continue
        col = i - line_start + 1
        if text.startswith("//", i):
            j = text.find("\n", i)
            j = n if j < 0 else j
            if keep_comments is not None:
                keep_comments.append((line, text[i:j]))
            i = j
            continue
        if text.startswith("/*", i):
            j = text.find("*/", i + 2)
            if j < 0:
                raise LexError(f"line {line}: unterminated /* comment")
            body = text[i:j + 2]
            if keep_comments is not None:
                keep_comments.append((line, body))
            line += body.count("\n")
            if "\n" in body:
                line_start = i + body.rfind("\n") + 1
            i = j + 2
            continue
        if c == '"':
            j = i + 1
            while j < n and text[j] != '"':
                if text[j] == "\\":
                    j += 1
                if j < n and text[j] == "\n":
                    raise LexError(f"line {line}: newline inside string")
                j += 1
            toks.append(Token(STRING, text[i:j + 1], line, col))
            i = j + 1
            continue
        if c == "'":
            j = text.find("'", i + 1)
            nl = text.find("\n", i + 1)
            if j < 0 or (0 <= nl < j):
                raise LexError(f"line {line}: unterminated 'name' literal")
            toks.append(Token(NAME, text[i:j + 1], line, col))
            i = j + 1
            continue
        if c == "`":
            # `macro or `macro(...balanced...)
            j = i + 1
            while j < n and (text[j].isalnum() or text[j] == "_"):
                j += 1
            if j < n and text[j] == "(":
                depth = 0
                while j < n:
                    if text[j] == "(":
                        depth += 1
                    elif text[j] == ")":
                        depth -= 1
                        if depth == 0:
                            j += 1
                            break
                    elif text[j] == '"':
                        j += 1
                        while j < n and text[j] != '"':
                            j += 2 if text[j] == "\\" else 1
                    elif text[j] == "\n":
                        line += 1
                        line_start = j + 1
                    j += 1
            toks.append(Token(MACRO, text[i:j], line, col))
            i = j
            continue
        if c == "#" and text[line_start:i].strip() == "":
            j = text.find("\n", i)
            j = n if j < 0 else j
            toks.append(Token(DIRECTIVE, text[i:j], line, col))
            i = j
            continue
        if c.isalpha() or c == "_":
            j = i + 1
            while j < n and (text[j].isalnum() or text[j] == "_"):
                j += 1
            toks.append(Token(IDENT, text[i:j], line, col))
            i = j
            continue
        if c.isdigit() or (c == "." and i + 1 < n and text[i + 1].isdigit()):
            j = i + 1
            if text.startswith(("0x", "0X"), i):
                j = i + 2
                while j < n and text[j] in "0123456789abcdefABCDEF":
                    j += 1
            else:
                while j < n and (text[j].isdigit() or text[j] == "."):
                    j += 1
                if j < n and text[j] in "eE" and j + 1 < n and (text[j + 1].isdigit() or text[j + 1] in "+-"):
                    j += 2
                    while j < n and text[j].isdigit():
                        j += 1
                if j < n and text[j] in "fF":
                    j += 1
            toks.append(Token(NUMBER, text[i:j], line, col))
            i = j
            continue
        for op in _OPS:
            if text.startswith(op, i):
                toks.append(Token(PUNCT, op, line, col))
                i += len(op)
                break
        else:
            raise LexError(f"line {line}: unexpected character {c!r}")
    return toks


def match_brace(toks: list[Token], i: int, open_="{", close="}") -> int:
    """Index of the token closing the bracket that opens at toks[i]."""
    depth = 0
    for j in range(i, len(toks)):
        t = toks[j]
        if t.kind == PUNCT:
            if t.text == open_:
                depth += 1
            elif t.text == close:
                depth -= 1
                if depth == 0:
                    return j
    raise LexError(f"line {toks[i].line}: unbalanced '{open_}'")


def find_punct(toks: list[Token], i: int, text: str) -> int:
    """Next index >= i whose token is the punctuation `text` (no nesting awareness)."""
    for j in range(i, len(toks)):
        if toks[j].kind == PUNCT and toks[j].text == text:
            return j
    raise LexError(f"line {toks[i].line if i < len(toks) else '?'}: expected '{text}'")
