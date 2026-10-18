#!/usr/bin/env python3
"""Assemble swing_*.p8 carts from src/ and report PICO-8 token counts."""
import re, sys, os

ROOT = os.path.dirname(os.path.abspath(__file__))
CARTS = {
    "swing_beats": ["core.lua", "beats.lua"],
    "swing_keys": ["core.lua", "keys.lua"],
    "swing_noise": ["core.lua", "noise.lua"],
}

TOKEN_RE = re.compile(r"""
    (?P<comment>--\[\[.*?\]\]|--[^\n]*)
  | (?P<str>"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|\[\[.*?\]\])
  | (?P<num>0x[0-9a-fA-F]+(?:\.[0-9a-fA-F]+)?|0b[01]+(?:\.[01]+)?|\d+\.?\d*|\.\d+)
  | (?P<name>[A-Za-z_][A-Za-z0-9_]*)
  | (?P<op>\.\.\.|\.\.=|\.\.|==|~=|!=|<=|>=|<<>|>><|>>>|<<|>>|\^\^|\+=|-=|\*=|/=|\\=|%=|\^=|\|=|&=|[-+*/%^#<>=(){}\[\];:,.~&|\\@$?!])
  | (?P<ws>\s+)
  | (?P<other>.)
""", re.S | re.X)

FREE_NAMES = {"end", "local"}
FREE_OPS = {",", ".", ":", ";", ")", "]", "}"}

def count_tokens(code):
    n = 0
    prev = None
    for m in TOKEN_RE.finditer(code):
        k = m.lastgroup
        v = m.group()
        if k in ("comment", "ws"):
            continue
        if k == "name":
            if v not in FREE_NAMES:
                n += 1
        elif k == "op":
            if v not in FREE_OPS:
                # unary minus before a number literal is free
                if v == "-" and prev in (None, "(", ",", "=", "{", "[", "return", "op") and False:
                    pass
                n += 1
        elif k in ("str", "num", "other"):
            n += 1
        prev = v
    return n

LANGS = {"es": 1, "en": 2}

def build(name, parts, lang="es"):
    code = "\n".join(open(os.path.join(ROOT, "src", p)).read() for p in parts)
    assert "\nlang=1\n" in code
    code = code.replace("\nlang=1\n", "\nlang=%d\n" % LANGS[lang], 1)
    toks = count_tokens(code)
    os.makedirs(os.path.join(ROOT, "carts", lang), exist_ok=True)
    out = os.path.join(ROOT, "carts", lang, name + ".p8")
    with open(out, "w") as f:
        f.write("pico-8 cartridge // http://www.pico-8.com\nversion 41\n__lua__\n")
        f.write(code)
        if not code.endswith("\n"):
            f.write("\n")
    return out, toks, len(code)

if __name__ == "__main__":
    which = sys.argv[1:] or list(CARTS)
    for w in which:
        parts = CARTS[w]
        if not all(os.path.exists(os.path.join(ROOT, "src", p)) for p in parts):
            print(w, "skip (missing src)")
            continue
        for lang in LANGS:
            out, toks, chars = build(w, parts, lang)
            flag = "OK" if toks <= 8192 else "OVER"
            print(f"carts/{lang}/{w}.p8: {toks} tokens ({flag}), {chars} chars")
