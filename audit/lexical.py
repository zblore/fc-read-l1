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
fc_path = os.path.join(root, ".lake/packages/formal_conjectures/FormalConjectures",
                       "Wikipedia/InvariantSubspaceProblem.lean")
fc = open(fc_path, encoding="utf-8").read()
# Read bytes, so CRLF line endings are seen rather than silently converted.
raw = {f: open(f, "rb").read() for f in files}
src = {f: b.decode("utf-8") for f, b in raw.items()}
decl_re = (r"^(?:@\[[^\]]*\]\s*)?(?:noncomputable\s+)?"
           r"(?:def|lemma|theorem|abbrev|structure)\s+(\S+)")
declared = set(re.findall(decl_re, "\n".join(src.values()), re.M))
declared |= set(re.findall(decl_re, fc, re.M))
problems = []
# audit/Vacuity.lean skips some suffixes as Lean-generated (its `generated` list, plus `eq_<n>`),
# so no hand-written name may use them. The list is read from Vacuity.lean so the two cannot drift.
vacuity = open(os.path.join(root, "audit", "Vacuity.lean"), encoding="utf-8").read()
generated_block = re.search(r"let generated : List String :=\s*\[(.*?)\]", vacuity, re.S)
if generated_block is None:
    sys.exit("lexical audit: cannot find the `generated` list in audit/Vacuity.lean")
reserved = set(re.findall(r'"([^"]+)"', generated_block.group(1)))
if len(reserved) < 10:
    sys.exit(f"lexical audit: only {len(reserved)} reserved suffixes read from Vacuity.lean")
for f, s in src.items():
    for name in re.findall(decl_re, s, re.M):
        last = name.split(".")[-1]
        if last in reserved or re.fullmatch(r"eq_\d+", last):
            problems.append(f"{f}: `{name}` uses a suffix reserved for Lean-generated lemmas")
for f, t in src.items():
    for doc in re.findall(r"/-[-!](.*?)-/", t, re.S):
        for name in re.findall(r"`([A-Za-z_][A-Za-z0-9_'.]*)`", doc):
            short = name.split(".")[-1]
            wordlike = "_" in short or short[:1].islower()
            # Qualified names such as `Finset.prod_add` or `lp.evalCLM` are taken to be
            # Mathlib's and are not checked, so a mistyped one would pass. Names here or in the
            # FC file are checked.
            qualified = ("." in name and (name[:1].isupper() or name.startswith("lp."))
                         and not name.startswith(("ReadL1.",
                                                  "InvariantSubspaceProblem.")))
            if (len(short) > 2 and short != "sorry" and wordlike
                    and short not in declared and not qualified):
                problems.append(f"{f}: docstring names `{name}`, "
                                "not declared here or in the FC file")
    code = re.sub(r"--[^\n]*", "", re.sub(r"/-.*?-/", "", t, flags=re.S))
    if re.search(r":=\s*True\b|\bsorry\b|\badmit\b|native_decide", code):
        problems.append(f"{f}: placeholder, sorry, admit or native_decide")
    for imp in re.findall(r"^import\s+(\S+)", t, re.M):
        if not (imp.startswith("ReadL1") or imp == "Mathlib"
                or imp == "FormalConjectures.Wikipedia.InvariantSubspaceProblem"):
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
print(f"lexical audit clean over {len(files)} files")
