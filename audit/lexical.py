"""Audit, lexical checks: doc promises, placeholders, import hygiene, format.

Run from the repository root, or pass the root as the first argument. Exits 1 if it finds any
problem, so it can gate CI.
"""
import glob
import os
import re
import sys

root = sys.argv[1] if len(sys.argv) > 1 else "."
files = sorted(glob.glob(os.path.join(root, "ReadL1", "*.lean")))
files.append(os.path.join(root, "ReadL1.lean"))
# Formal Conjectures' text, as copied into Challenge.lean (scripts/check-fc-match.py checks it).
fc = open(os.path.join(root, "Challenge.lean"), encoding="utf-8").read()
# Read bytes, so CRLF line endings are seen rather than silently converted.
raw = {f: open(f, "rb").read() for f in files}
src = {f: b.decode("utf-8") for f, b in raw.items()}
# Any order of modifiers, so `private`, `public` and `protected` declarations are seen too.
decl_re = (r"^(?:@\[[^\]]*\]\s*)?"
           r"(?:(?:private|public|protected|noncomputable|partial|nonrec|unsafe)\s+)*"
           r"(?:def|lemma|theorem|abbrev|structure|inductive|class)\s+([^\s:({\[]+)")
declared = set(re.findall(decl_re, "\n".join(src.values()), re.M))
declared |= set(re.findall(decl_re, fc, re.M))
problems = []
# audit/Vacuity.lean skips some suffixes as Lean-generated (its `generated` list, `eq_<n>` and
# `match_<n>`), so no hand-written name may use them. The list is read from Vacuity.lean so the
# two cannot drift.
vacuity = open(os.path.join(root, "audit", "Vacuity.lean"), encoding="utf-8").read()
generated_block = re.search(r"let generated : List String :=\s*\[(.*?)\]", vacuity, re.S)
if generated_block is None:
    sys.exit("lexical audit: cannot find the `generated` list in audit/Vacuity.lean")
reserved = set(re.findall(r'"([^"]+)"', generated_block.group(1)))
if len(reserved) < 10:
    sys.exit(f"lexical audit: only {len(reserved)} reserved suffixes read from Vacuity.lean")


def uses_reserved(name):
    """The rule of Vacuity's `isGenerated`: a reserved or `eq_<n>` last component, or a
    `match_<n>` component anywhere in the name."""
    parts = name.split(".")
    return (parts[-1] in reserved or re.fullmatch(r"eq_\d+", parts[-1]) is not None
            or any(re.fullmatch(r"match_\d+", c) for c in parts))


# Negative controls: each line declares a name Vacuity would skip, so each must be caught.
controls = [
    "private def auditBlindSpot.eq_def : Nat := 0",
    "public theorem a.eq_2 : True := trivial",
    "@[simp] private noncomputable def b.match_1.foo : Nat := 0",
    "protected lemma c.rec : True := trivial",
    "noncomputable def d.splitter := 0",
]
for line in controls:
    names = re.findall(decl_re, line, re.M)
    if len(names) != 1 or not uses_reserved(names[0]):
        sys.exit(f"lexical audit: control not caught: {line}")
for f, s in src.items():
    for name in re.findall(decl_re, s, re.M):
        if uses_reserved(name):
            problems.append(f"{f}: `{name}` uses a name reserved for Lean-generated lemmas")
for f, t in src.items():
    for doc in re.findall(r"/-[-!](.*?)-/", t, re.S):
        for name in re.findall(r"`([A-Za-z_][A-Za-z0-9_'.]*)`", doc):
            short = name.split(".")[-1]
            wordlike = "_" in short or short[:1].islower()
            # Qualified names such as `Finset.prod_add` or `lp.evalCLM` are taken to be
            # Mathlib's and are not checked, so a mistyped one would pass. Names here or in
            # Challenge.lean are checked.
            qualified = ("." in name and (name[:1].isupper() or name.startswith("lp."))
                         and not name.startswith(("ReadL1.",
                                                  "InvariantSubspaceProblem.")))
            if (len(short) > 2 and short != "sorry" and wordlike
                    and short not in declared and not qualified):
                problems.append(f"{f}: docstring names `{name}`, "
                                "not declared here or in Challenge.lean")
    code = re.sub(r"--[^\n]*", "", re.sub(r"/-.*?-/", "", t, flags=re.S))
    if re.search(r":=\s*True\b|\bsorry\b|\badmit\b|native_decide", code):
        problems.append(f"{f}: placeholder, sorry, admit or native_decide")
    for imp in re.findall(r"^(?:public\s+)?import\s+(\S+)", t, re.M):
        if not (imp.startswith("ReadL1") or imp == "Mathlib"):
            problems.append(f"{f}: imports {imp}")
    for i, line in enumerate(t.replace("\r\n", "\n").split("\n"), 1):
        if len(line) > 100:
            problems.append(f"{f}:{i}: {len(line)} characters")
        if line != line.rstrip():
            problems.append(f"{f}:{i}: trailing whitespace")
    if b"\r" in raw[f]:
        problems.append(f"{f}: CRLF line endings")
if problems:
    print("\n".join(problems))
    sys.exit(1)
print(f"lexical audit clean over {len(files)} files; {len(controls)} controls caught")
