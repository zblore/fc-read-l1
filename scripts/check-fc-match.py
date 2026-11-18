#!/usr/bin/env python3
"""Check that Challenge.lean states Formal Conjectures' ℓ¹ statement, and nothing else.

Palomar's Comparator checks that Solution proves the statement of Challenge.lean, with the same
definitions. This script checks the other link: that Challenge.lean is Formal Conjectures' text.

The check regenerates Challenge.lean's code from Formal Conjectures'
`FormalConjectures/Wikipedia/InvariantSubspaceProblem.lean` at FC_COMMIT and requires an exact
match. Challenge.lean must be:

* a header comment, `module`, `public import Mathlib` and a module docstring, and nothing else
  (free-text comments may not contain `/-`, so nested comments cannot hide or expose code);
* then, character for character, the text that `expected_challenge` builds:
  - `@[expose] public section`, `namespace InvariantSubspaceProblem`, Formal Conjectures'
    `variable` line and its structure `ClosedInvariantSubspace` with its docstring;
  - Formal Conjectures' statement `Invariant_subspace_problem_l1` with its docstring and without
    its `category`/`AMS` attribute, ending `by sorry`; then `end InvariantSubspaceProblem`.

The statement keeps Formal Conjectures' name, `InvariantSubspaceProblem.Invariant_subspace_problem_l1`,
which has no escaped name component, so Palomar accepts it as it is.

`ReadL1/Defs.lean` is checked the same way, as a regression check; Comparator is what guarantees
that it agrees with Challenge.lean.

On the Formal Conjectures side the script requires the source file to have the SHA-256 recorded in
`FC_SHA256`, so any change to it, including a move of `FC_COMMIT`, fails until someone has read the
new text and updated the record. At this commit, read by hand, the text before the statement
contains:

* commands: `module`, the import, `@[expose] public section`, `namespace`, `variable`;
* declarations: the structure, the open statement `Invariant_subspace_problem`, the statements
  `Invariant_subspace_problem_finite_dimensional` and `Invariant_subspace_problem_non_separable`
  with their proofs, the lemma `TopologicalSpace.nontrivial_of_not_separableSpace`, and the
  statement `Invariant_subspace_problem_normal_operator`.

It contains no notation, macro, `run_cmd`, `set_option`, `attribute` or `open`, and none of those
declarations is used by the ℓ¹ statement, which mentions only `lp` and `ClosedInvariantSubspace`.

What this script does not establish: it compares text. It does not read what that file imports.
`FormalConjecturesUtil` imports Mathlib and the `FormalConjecturesForMathlib` umbrella. Formal
Conjectures builds with Lean and Mathlib v4.33.1, this repository with Lean v4.35.0-rc3 and a later
Mathlib. So this is a check that the text is the same, not a proof that the text elaborates to the
same terms in Formal Conjectures' own environment.

Usage:
  check-fc-match.py [FC_CHECKOUT]   check; without an argument, download FC at FC_COMMIT
  check-fc-match.py --self-test [FC_CHECKOUT]
                                    check, then confirm that a list of altered Challenge, Defs and
                                    Formal Conjectures files all fail
  check-fc-match.py --print-expected [FC_CHECKOUT]
                                    print the code Challenge.lean must contain, then a line
                                    `=== DEFS ===`, then the code ReadL1/Defs.lean must contain
"""
import hashlib
import re
import subprocess
import sys
import urllib.request
from pathlib import Path

FC_COMMIT = "40a8592cb6f7e96cb9a8275d96bb3e013feeb1dc"
SOURCE = "FormalConjectures/Wikipedia/InvariantSubspaceProblem.lean"
# The source file at FC_COMMIT, with line endings normalised. See the module docstring.
FC_SHA256 = "a53801cd5d6938193d7f1a5cbb95ec0f469b6a04854ba6c4803f35f17a5efe34"
EXPOSE = "@[expose] public section\n"
NS = "namespace InvariantSubspaceProblem\n"
VARIABLE = "variable {H : Type*} [NormedAddCommGroup H]\n"
ATTR = "@[category research solved, AMS 47]\n"
NAME = "Invariant_subspace_problem_l1"
END = "end InvariantSubspaceProblem\n"

ROOT = Path(__file__).resolve().parent.parent


class Mismatch(Exception):
    pass


def fetch(checkout):
    if checkout:
        out = subprocess.run(["git", "-C", checkout, "show", f"{FC_COMMIT}:{SOURCE}"],
                             capture_output=True, check=True).stdout
    else:
        url = f"https://raw.githubusercontent.com/google-deepmind/formal-conjectures/{FC_COMMIT}/{SOURCE}"
        with urllib.request.urlopen(url) as r:
            out = r.read()
    return out.decode("utf8").replace("\r\n", "\n")


def pieces(fc):
    if hashlib.sha256(fc.encode("utf8")).hexdigest() != FC_SHA256:
        raise Mismatch(f"{SOURCE}: differs from the text read at FC_COMMIT (SHA-256)")
    for needle in [EXPOSE, NS, VARIABLE, END]:
        if fc.count(needle) != 1:
            raise Mismatch(f"Formal Conjectures: {needle.strip()!r} not found exactly once")
    head = EXPOSE + "\n" + NS + "\n" + VARIABLE + "\n"
    if head not in fc:
        raise Mismatch("Formal Conjectures: the expose, namespace and variable lines are not together")
    a = fc.index(head) + len(head)
    if not fc.startswith("/-- `ClosedInvariantSubspace T`", a):
        raise Mismatch("Formal Conjectures: the structure does not follow the variable line")
    b = fc.index("\n\n/--", a)
    structure = fc[a:b]
    if not re.search(r"^structure ClosedInvariantSubspace ", structure, re.M):
        raise Mismatch("Formal Conjectures: the structure has changed")
    t = fc.index(f"\ntheorem {NAME} ")
    s = fc.rindex("\n/--", 0, t) + 1
    e = fc.index("  sorry\n", t) + len("  sorry\n")
    block = fc[s:e]
    if block.count(ATTR) != 1:
        raise Mismatch(f"Formal Conjectures: {NAME} does not carry {ATTR.strip()}")
    if fc[e:].strip() != END.strip():
        raise Mismatch(f"Formal Conjectures: something follows {NAME} before the end of the namespace")
    return structure, block.replace(ATTR, "").rstrip("\n")


def common(structure):
    return EXPOSE + "\n" + NS + "\n" + VARIABLE + "\n" + structure + "\n"


def expected_challenge(fc):
    structure, stmt = pieces(fc)
    return common(structure) + "\n" + stmt + "\n\n" + END


def expected_defs(fc):
    return common(pieces(fc)[0]) + "\n" + END


# A comment ends at its first `-/`, as it does for Lean, and may not contain `/-`.
COMMENT_BODY = r"(?:(?!-/|/-)[\s\S])*"
PREAMBLE = re.compile(r"\A(?:/-" + COMMENT_BODY + r"-/\s*)?module\n\npublic import Mathlib\n\n"
                      r"/-!" + COMMENT_BODY + r"-/\n\n")


def check_file(path, text, expected):
    m = PREAMBLE.match(text)
    if not m:
        raise Mismatch(f"{path}: the preamble is not a header, `module`, `public import Mathlib` "
                       "and a module docstring")
    if text[m.end():] != expected:
        rest = text[m.end():]
        n = next((i for i, (x, y) in enumerate(zip(rest, expected)) if x != y),
                 min(len(rest), len(expected)))
        line = rest.count("\n", 0, n) + 1
        raise Mismatch(f"{path}: differs from Formal Conjectures' text at code line {line}")


def run(challenge, defs, fc):
    check_file("Challenge.lean", challenge, expected_challenge(fc))
    check_file("ReadL1/Defs.lean", defs, expected_defs(fc))


def mutations(challenge, defs, fc):
    """Altered inputs, each of which must fail."""
    def sub(text, a, b):
        assert text.count(a) >= 1, a
        return text.replace(a, b, 1)
    c, d = challenge, defs
    yield "Challenge: ℓ¹ replaced by ℓ²", sub(c, "(lp (fun (_ : ℕ) => ℂ) 1) →L[ℂ] (lp (fun (_ : ℕ) => ℂ) 1)", "(lp (fun (_ : ℕ) => ℂ) 2) →L[ℂ] (lp (fun (_ : ℕ) => ℂ) 2)"), d, fc
    yield "Challenge: conclusion weakened", sub(c, "IsEmpty (ClosedInvariantSubspace T)", "True"), d, fc
    yield "Challenge: conclusion negated", sub(c, "IsEmpty (ClosedInvariantSubspace T)", "Nonempty (ClosedInvariantSubspace T)"), d, fc
    yield "Challenge: a field dropped", sub(c, "  ne_top : toSubspace ≠ ⊤\n", ""), d, fc
    yield "Challenge: closedness dropped", sub(c, "  is_closed : IsClosed (toSubspace : Set H)\n", ""), d, fc
    yield "Challenge: invariance weakened", sub(c, "toSubspace.map T.toLinearMap ≤ toSubspace", "True"), d, fc
    yield "Challenge: the variable line changed", sub(c, VARIABLE, "variable {H : Type} [NormedAddCommGroup H]\n"), d, fc
    yield "Challenge: a notation added", sub(c, NS, NS + "\nlocal notation \"ℂ\" => ℝ\n"), d, fc
    yield "Challenge: the statement renamed", sub(c, f"theorem {NAME}", f"theorem {NAME}'"), d, fc
    yield "Challenge: the statement proved", sub(c, "  sorry\n", "  exact absurd rfl (by sorry)\n"), d, fc
    yield "Challenge: code before the expose line", sub(c, EXPOSE, "set_option autoImplicit true\n\n" + EXPOSE), d, fc
    yield "Challenge: code hidden in a nested comment", sub(c, "/-!", "/-! /- -/"), d, fc
    yield "Challenge: an extra theorem", c + "\ntheorem extra : True := trivial\n", d, fc
    yield "Challenge: an axiom after an early end of the docstring", sub(c, "-/\n\n" + EXPOSE, "-/\naxiom Injected : False\n-- -/\n\n" + EXPOSE), d, fc
    yield "Defs: a field dropped", c, sub(d, "  ne_bot : toSubspace ≠ ⊥\n", ""), fc
    yield "Defs: the structure renamed", c, sub(d, "structure ClosedInvariantSubspace ", "structure ClosedInvariantSubspace' "), fc
    yield "Defs: the namespace changed", c, sub(d, NS, "namespace InvariantSubspaceProblem'\n"), fc
    yield "FC: a notation before the statement", c, d, sub(fc, "/--\nThere exists a bounded linear operator", "local notation \"ℂ\" => ℝ\n\n/--\nThere exists a bounded linear operator")
    yield "FC: a variable before the statement", c, d, sub(fc, "/--\nThere exists a bounded linear operator", "variable (extra : False)\ninclude extra\n\n/--\nThere exists a bounded linear operator")
    yield "FC: an extra attribute on the statement", c, d, sub(fc, ATTR + f"theorem {NAME}", f"@[category research solved, AMS 47, simp]\ntheorem {NAME}")
    yield "FC: an extra import", c, d, sub(fc, EXPOSE, "public import Mathlib.Logic.Basic\n" + EXPOSE)
    yield "FC: the statement marked open", c, d, sub(fc, ATTR + f"theorem {NAME}", f"@[category research open, AMS 47]\ntheorem {NAME}")


def main(argv):
    sys.stdout.reconfigure(encoding="utf-8")
    self_test = "--self-test" in argv
    printing = "--print-expected" in argv
    args = [a for a in argv if a not in ("--self-test", "--print-expected")]
    checkout = args[0] if args else None
    fc = fetch(checkout)
    if printing:
        sys.stdout.write(expected_challenge(fc) + "=== DEFS ===\n" + expected_defs(fc))
        return 0
    challenge = (ROOT / "Challenge.lean").read_text(encoding="utf8")
    defs = (ROOT / "ReadL1" / "Defs.lean").read_text(encoding="utf8")
    try:
        run(challenge, defs, fc)
    except Mismatch as e:
        print(f"FAIL: {e}")
        return 1
    source = f"Formal Conjectures {'checkout ' + checkout if checkout else 'from GitHub'} at {FC_COMMIT}"
    print(f"OK: Challenge.lean is Formal Conjectures' structure and statement, and nothing else ({source})")
    if not self_test:
        return 0
    count = 0
    for label, c, d, f in mutations(challenge, defs, fc):
        count += 1
        try:
            run(c, d, f)
        except (Mismatch, ValueError) as e:
            print(f"  fails as it should: {label}: {e}")
            continue
        print(f"FAIL: self-test: {label} passed the check")
        return 1
    print(f"OK: self-test, all {count} altered files fail")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
