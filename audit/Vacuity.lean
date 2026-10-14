/-
Copyright (c) 2026 Zayn Blore. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Zayn Blore
-/
import ReadL1

/-!
Audit: every hand-written declaration in `ReadL1`, private ones included, is reachable from the
headline result: it occurs, directly or through other `ReadL1` declarations, in the statement or
proof of `ReadL1.invariant_subspace_problem_l1`. Any unreachable declaration is an error, so
`lake env lean` exits nonzero. As a control, an orphan recursive definition whose equation lemma
mentions it must be reported, which shows the check can fail; an audit that counted any mention
as a use would pass it.
-/

open Lean Elab Command

namespace ReadL1Audit

/-- `n` is a `ReadL1` name; a private name counts by its user-facing form. -/
def inReadL1 (n : Name) : Bool := (`ReadL1).isPrefixOf (privateToUserName n)

/-- The hand-written declarations of `ReadL1`: everything under the prefix except internal names,
constructors, recursors, inductive types and the lemmas Lean generates. -/
def handWritten (env : Environment) : Array Name :=
  -- Lean generates equation lemmas (`xPow.eq_1`, `eq_def`, `eq_unfold`), congruence lemmas
  -- (`congr_simp`) and, for structures and inductives, constructors, projections, recursors,
  -- `ext`/`injEq` lemmas and per-constructor eliminators (`Kind.J.elim`, `Kind.ctorElim`), none
  -- written by hand.
  -- They are recognised by name only, so these suffixes are reserved: never use them for a
  -- hand-written declaration (`audit/lexical.py` enforces this, reading this list).
  let generated : List String :=
    ["congr_simp", "eq_def", "eq_unfold", "mk", "injEq", "inj", "ext", "ext_iff", "rec",
      "recOn", "casesOn", "noConfusion", "noConfusionType", "ctorIdx", "toCtorIdx", "sizeOf_spec",
      "brecOn", "below", "binductionOn", "ibelow", "elim", "ctorElim", "ctorElimType",
      "splitter"]
  -- Pattern matches compile to auxiliaries `f.match_1`, `f.match_2`, … (and lemmas about them).
  let numbered (pre : String) (s : String) : Bool :=
    s.startsWith pre && s.length > pre.length && (s.toList.drop pre.length).all Char.isDigit
  let isGenerated (n : Name) : Bool :=
    (match n with
      | .str _ s => generated.contains s || numbered "eq_" s
      | _ => false) ||
    n.components.any fun c ↦ match c with
      | .str _ s => numbered "match_" s
      | _ => false
  env.constants.fold (fun (acc : Array Name) n ci ↦
    let u := privateToUserName n
    if inReadL1 n && !u.isInternal && !isGenerated u &&
        !(ci matches .ctorInfo _ | .recInfo _ | .inductInfo _) then acc.push n else acc) #[]

/-- The constants a declaration mentions: in its type, its value, and, for an inductive type,
its constructors. -/
def mentions (ci : ConstantInfo) : Array Name :=
  let value := match ci with
    | .thmInfo t => t.value.getUsedConstants
    | .defnInfo d => d.value.getUsedConstants
    | .opaqueInfo o => o.value.getUsedConstants
    | .inductInfo i => i.ctors.toArray
    | _ => #[]
  ci.type.getUsedConstants ++ value

/-- The `ReadL1` constants reachable from `todo`. Constants outside `ReadL1` are not followed,
since nothing outside the project mentions it. -/
partial def reachable (env : Environment) (todo : List Name) (seen : NameSet := {}) : NameSet :=
  match todo with
  | [] => seen
  | n :: rest =>
    if seen.contains n || !inReadL1 n then reachable env rest seen
    else
      let next := (env.find? n).map (fun ci ↦ (mentions ci).toList) |>.getD []
      reachable env (next ++ rest) (seen.insert n)

/-- The hand-written `ReadL1` declarations not reachable from `roots`. -/
def unreachable (env : Environment) (roots : List Name) : Array Name :=
  let seen := reachable env roots
  (handWritten env).filter fun n ↦ !seen.contains n

end ReadL1Audit

/-- Control: an orphan recursive definition. Its equation lemma (realised below) mentions it, so
an audit that counted any mention as a use would pass it; this one must report it. -/
def ReadL1.vacuityControl : ℕ → ℕ
  | 0 => 0
  | n + 1 => ReadL1.vacuityControl n

open ReadL1Audit in
run_cmd do
  let roots : List Name := [`ReadL1.invariant_subspace_problem_l1]
  let control : Name := `ReadL1.vacuityControl
  for r in roots do
    if ((← getEnv).find? r).isNone then throwError m!"{r} missing"
  let eqn ← liftTermElabM <| realizeGlobalConstNoOverloadCore (control ++ `eq_1)
  let env ← getEnv
  unless (env.find? eqn).isSome do
    throwError "control failed: its equation lemma was not generated"
  let ours := (handWritten env).filter (· != control)
  let orphans := unreachable env roots
  unless orphans.contains control do
    throwError "control failed: an orphan definition was not reported"
  let real := orphans.filter (· != control)
  unless real.isEmpty do
    throwError m!"declarations not reachable from the headline: {real.toList}"
  unless ours.size ≥ 200 do throwError m!"only {ours.size} declarations found; wrong prefix?"
  let msg := s!"vacuity audit passed: {ours.size} declarations, all reachable from the headline"
  logInfo m!"{msg}; control ok"
