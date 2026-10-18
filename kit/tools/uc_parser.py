"""Declaration-level parser for UnrealScript classes, built on uc_lexer.

parse_file(text) -> ParsedFile with one Decl per class / var / const / struct / enum /
function / event / delegate / state / label / defaultproperties. Bodies are not parsed into
an AST; validators walk the token ranges each Decl records.
"""
from __future__ import annotations

from dataclasses import dataclass, field

from uc_lexer import IDENT, PUNCT, LexError, Token, match_brace, tokenize

FUNC_WORDS = {"function", "event", "delegate", "operator", "preoperator", "postoperator"}
FUNC_MODS = {
    "simulated", "final", "static", "native", "private", "protected", "public", "latent",
    "iterator", "singular", "exec", "reliable", "unreliable", "server", "client", "noexport",
    "const", "coerce", "noexportheader", "virtual", "intrinsic", "transient", "editoronly",
}
STATE_MODS = {"auto", "simulated"}
SKIP_BLOCKS = {"replication", "cpptext", "structcpptext"}


@dataclass
class Param:
    type: str
    name: str
    mods: list[str] = field(default_factory=list)  # out, optional, coerce, const


@dataclass
class Decl:
    kind: str           # class|var|const|struct|enum|function|event|state|label|defaultproperties
    name: str
    line: int           # declaration line (first modifier / keyword)
    end: int            # last line (closing brace or ';')
    tok_start: int
    tok_end: int        # index of the closing '}' / ';'
    state: str | None = None          # enclosing state, for functions/labels inside a state
    signature: str = ""
    body_open: int | None = None      # token index of '{' (functions/states/structs/enums)
    mods: list[str] = field(default_factory=list)
    return_type: str = ""
    params: list[Param] = field(default_factory=list)
    parent: str = ""                  # extends target (class / state / struct)
    ignores: list[str] = field(default_factory=list)
    label_code: tuple[int, int] | None = None  # (first label token, closing brace) for states
    var_type: str = ""
    owner: str = ""                   # for struct members: the struct name
    values: list[str] = field(default_factory=list)  # enum values

    @property
    def qual(self) -> str:
        return f"{self.state}.{self.name}" if self.state else self.name


@dataclass
class ParsedFile:
    tokens: list[Token]
    decls: list[Decl]
    comments: list[tuple[int, str]]
    class_name: str = ""
    parent: str = ""
    class_mods: list[str] = field(default_factory=list)

    def by_kind(self, *kinds: str) -> list[Decl]:
        return [d for d in self.decls if d.kind in kinds]


def join_tokens(toks: list[Token]) -> str:
    out = ""
    for t in toks:
        s = t.text
        if not out:
            out = s
        elif s in (",", ")", "]", ">", ";", ".") or out.endswith(("(", "[", "<", ".")):
            out += s
        elif s in ("(", "[", "<") and out[-1:].isalnum():
            out += s
        else:
            out += " " + s
    return out


def _skip_group(toks, i, open_, close):
    return match_brace(toks, i, open_, close) + 1 if toks[i].text == open_ else i


def _parse_type(toks, i):
    """Parse a type starting at toks[i]; return (type_text, next_index)."""
    j = i + 1
    if j < len(toks) and toks[j].text == "<":
        depth = 0
        while j < len(toks):
            if toks[j].text == "<":
                depth += 1
            elif toks[j].text == ">":
                depth -= 1
            elif toks[j].text == ">>":
                depth -= 2
            j += 1
            if depth <= 0:
                break
    return join_tokens(toks[i:j]), j


class _Parser:
    def __init__(self, text: str):
        self.comments: list = []
        self.t = tokenize(text, self.comments)
        self.decls: list[Decl] = []
        self.pf = ParsedFile(self.t, self.decls, self.comments)

    # --- helpers -------------------------------------------------------------------------
    def end_stmt(self, i):
        """Index of the ';' ending the statement at i, skipping balanced (), {}, []."""
        t = self.t
        while i < len(t):
            x = t[i]
            if x.kind == PUNCT:
                if x.text in "({[":
                    i = match_brace(t, i, x.text, {"(": ")", "{": "}", "[": "]"}[x.text])
                elif x.text == ";":
                    return i
            i += 1
        raise LexError("missing ';' at end of file")

    def add(self, kind, name, i0, i1, **kw):
        d = Decl(kind, name, self.t[i0].line, self.t[i1].line, i0, i1, **kw)
        self.decls.append(d)
        return d

    # --- top level -----------------------------------------------------------------------
    def parse(self):
        t, i = self.t, 0
        while i < len(t):
            i = self.decl(i, state=None)
        return self.pf

    def decl(self, i, state):
        """Parse one declaration at i (class scope or state scope). Returns next index."""
        t = self.t
        tok = t[i]
        w = tok.low if tok.kind == IDENT else tok.text
        if tok.kind != IDENT:
            return i + 1  # stray ';' or directive
        if w == "class" and state is None and not self.pf.class_name:
            j = self.end_stmt(i)
            hdr = t[i + 1:j]
            self.pf.class_name = hdr[0].text
            for k, x in enumerate(hdr):
                if x.is_("extends") and k + 1 < len(hdr):
                    self.pf.parent = hdr[k + 1].text
            self.pf.class_mods = [x.low for x in hdr[1:] if x.kind == IDENT]
            self.add("class", hdr[0].text, i, j, signature=join_tokens(t[i:j]), parent=self.pf.parent)
            return j + 1
        if w == "var":
            return self.var(i, state)
        if w == "local":
            return self.end_stmt(i) + 1
        if w == "const":
            j = self.end_stmt(i)
            self.add("const", t[i + 1].text, i, j, state=state, signature=join_tokens(t[i:j]))
            return j + 1
        if w in ("struct", "enum"):
            return self.struct_enum(i, w, state)
        if w in ("defaultproperties", "structdefaultproperties"):
            o = i + 1
            c = match_brace(t, o)
            if w == "defaultproperties":
                self.add("defaultproperties", "defaultproperties", i, c, body_open=o)
            return c + 1
        if w in SKIP_BLOCKS and i + 1 < len(t) and t[i + 1].text == "{":
            return match_brace(t, i + 1) + 1
        if w == "ignores" and state:
            j = self.end_stmt(i)
            names = [x.text for x in t[i + 1:j] if x.kind == IDENT]
            for d in reversed(self.decls):
                if d.kind == "state" and d.name == state:
                    d.ignores.extend(names)
                    break
            return j + 1
        # function / state with modifiers
        j = i
        mods = []
        while j < len(t) and t[j].kind == IDENT and (t[j].low in FUNC_MODS or t[j].low in STATE_MODS):
            mods.append(t[j].low)
            j += 1
            if j < len(t) and t[j].text == "(":  # native(123)
                j = match_brace(t, j, "(", ")") + 1
        if j < len(t) and t[j].kind == IDENT and t[j].low in FUNC_WORDS:
            return self.function(i, j, mods, state)
        if j < len(t) and t[j].is_("state") and state is None:
            return self.state(i, j, mods)
        # anything else: skip a statement (unknown construct; validator reports if needed)
        return self.end_stmt(i) + 1

    def var(self, i, state):
        t = self.t
        j = self.end_stmt(i)
        k = i + 1
        mods = []
        if t[k].text == "(":  # var(Category) -> editable in the editor
            k = match_brace(t, k, "(", ")") + 1
            mods.append("editable")
        while t[k].kind == IDENT and t[k].low in {
                "config", "globalconfig", "transient", "const", "editconst", "native", "private",
                "protected", "public", "localized", "instanced", "export", "noexport", "repnotify",
                "duplicatetransient", "noimport", "editinline", "edfindable", "deprecated",
                "databinding", "editoronly", "notforconsole", "archetype", "crosslevelactive",
                "crosslevelpassive", "privatewrite", "protectedwrite", "init", "noclear",
                "interp", "input", "editfixedsize", "editinlineuse", "serializetext"}:
            mods.append(t[k].low)
            k += 1
            if t[k].text == "(":
                k = match_brace(t, k, "(", ")") + 1
        if t[k].is_("struct", "enum") and any(x.text == "{" for x in t[k:j]):
            o = next(n for n in range(k, j) if t[n].text == "{")
            k = match_brace(t, o) + 1
            vtype = "inline " + t[k - 1].text
        else:
            vtype, k = _parse_type(t, k)
        # names: split remaining tokens on top-level ','; strip [N] and <metadata>
        groups, cur, depth = [], [], 0
        for x in t[k:j]:
            if x.text in ("[", "<", "("):
                depth += 1
            elif x.text in ("]", ">", ")"):
                depth -= 1
            if x.text == "," and depth == 0:
                groups.append(cur)
                cur = []
            elif depth == 0 and x.kind == IDENT:
                cur.append(x)
        groups.append(cur)
        for g in groups:
            if g:
                d = self.add("var", g[0].text, i, j, state=state, mods=mods, var_type=vtype,
                             signature=f"var {vtype} {g[0].text}")
        return j + 1

    def struct_enum(self, i, kind, state):
        t = self.t
        o = i
        while t[o].text not in ("{", ";"):
            o += 1
        if t[o].text == ";":  # forward decl
            return o + 1
        hdr = [x for x in t[i + 1:o] if x.kind == IDENT]
        parent = ""
        names = [x.text for x in hdr]
        if "extends" in [n.lower() for n in names]:
            k = [n.lower() for n in names].index("extends")
            parent = names[k + 1] if k + 1 < len(names) else ""
            name = names[k - 1]
        else:
            name = names[-1]
        c = match_brace(t, o)
        end = c + 1 if c + 1 < len(t) and t[c + 1].text == ";" else c
        d = self.add(kind, name, i, end, state=state, body_open=o, parent=parent,
                     signature=f"{kind} {name}" + (f" extends {parent}" if parent else ""))
        if kind == "enum":
            d.values = [x.text for x in t[o + 1:c] if x.kind == IDENT]
        else:
            q = o + 1
            while q < c:
                if t[q].is_("var"):
                    n0 = len(self.decls)
                    q = self.var(q, state)
                    for m in self.decls[n0:]:
                        m.kind, m.owner = "member", name
                elif t[q].is_("structdefaultproperties", "structcpptext") and t[q + 1].text == "{":
                    q = match_brace(t, q + 1) + 1
                else:
                    q += 1
        return end + 1

    def function(self, i, j, mods, state):
        t = self.t
        word = t[j].low
        p = j + 1
        while p < len(t) and t[p].text != "(":
            p += 1
        head = t[j + 1:p]
        name = head[-1].text
        rtype = join_tokens(head[:-1]) if len(head) > 1 else ""
        pc = match_brace(t, p, "(", ")")
        params, cur = [], []
        depth = 0
        for x in t[p + 1:pc] + [Token(PUNCT, ",", 0, 0)]:
            if x.text in ("<", "[", "("):
                depth += 1
            elif x.text in (">", "]", ")"):
                depth -= 1
            if x.text == "," and depth == 0:
                if cur:
                    pm = [y.low for y in cur if y.kind == IDENT and y.low in ("out", "optional", "coerce", "const", "skip")]
                    rest = [y for y in cur if not (y.kind == IDENT and y.low in ("out", "optional", "coerce", "const", "skip"))]
                    eq = next((n for n, y in enumerate(rest) if y.text == "="), len(rest))
                    rest = rest[:eq]
                    idents = [n for n, y in enumerate(rest) if y.kind == IDENT]
                    nm = rest[idents[-1]].text if idents else "?"
                    params.append(Param(join_tokens(rest[:idents[-1]]) if idents else "", nm, pm))
                cur = []
            else:
                cur.append(x)
        k = pc + 1
        while k < len(t) and t[k].kind == IDENT and t[k].low in FUNC_MODS:
            k += 1
        sig = join_tokens(t[i:k])
        kind = "event" if word == "event" else "function"
        if word == "delegate":
            mods = mods + ["delegate"]
        if k < len(t) and t[k].text == "{":
            c = match_brace(t, k)
            self.add(kind, name, i, c, state=state, signature=sig, body_open=k, mods=mods,
                     return_type=rtype, params=params)
            return c + 1
        self.add(kind, name, i, k, state=state, signature=sig, mods=mods, return_type=rtype, params=params)
        return k + 1

    def state(self, i, j, mods):
        t = self.t
        k = j + 1
        if t[k].text == "(":
            k = match_brace(t, k, "(", ")") + 1
        name = t[k].text
        parent = ""
        k += 1
        if t[k].is_("extends"):
            parent = t[k + 1].text
            k += 2
        o = k
        c = match_brace(t, o)
        d = self.add("state", name, i, c, signature=join_tokens(t[i:o]), body_open=o, mods=mods, parent=parent)
        q = o + 1
        first_label = None
        while q < c:
            x = t[q]
            at_stmt_start = t[q - 1].text in (";", "{", "}", ":") and not (t[q - 1].text == ":" and first_label is None and q - 1 != o)
            if (x.kind == IDENT and at_stmt_start and q + 1 < c and t[q + 1].text == ":"
                    and x.low not in ("default", "case")):
                if first_label is None:
                    first_label = q
                self.add("label", x.text, q, q + 1, state=name, signature=f"{name}.{x.text}:")
                q += 2
                continue
            if first_label is not None:
                q += 1 if x.text != "{" else 0
                if x.text == "{":
                    q = match_brace(t, q) + 1
                continue
            q = self.decl(q, state=name)
        if first_label is not None:
            d.label_code = (first_label, c)
        return c + 1


def parse_file(text: str) -> ParsedFile:
    return _Parser(text).parse()
