/-
Copyright (c) 2026 Zayn Blore. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Zayn Blore
-/
import ReadL1

/-!
Audit: the headline statement is the same term as Formal Conjectures'
`Invariant_subspace_problem_l1`, and the main results use only the three standard axioms. Any
failure is an error, so `lake env lean` exits nonzero. As a control, Formal Conjectures' own
declaration must show `sorryAx`, which shows the axiom check can fail.
-/

open Lean Elab Command in
run_cmd do
  let env ← getEnv
  let some ours := env.find? `ReadL1.invariant_subspace_problem_l1
    | throwError "ReadL1.invariant_subspace_problem_l1 missing"
  let some theirs := env.find? `InvariantSubspaceProblem.Invariant_subspace_problem_l1
    | throwError "InvariantSubspaceProblem.Invariant_subspace_problem_l1 missing"
  unless ours.type == theirs.type do
    throwError m!"statements differ: {ours.type} vs {theirs.type}"
  unless ours.levelParams == theirs.levelParams do
    throwError m!"universe parameters differ: {ours.levelParams} vs {theirs.levelParams}"
  let standard : List Name := [``propext, ``Classical.choice, ``Quot.sound]
  for n in [`ReadL1.invariant_subspace_problem_l1, `ReadL1.theorem7, `ReadL1.theorem7Hyp_dRead,
      `ReadL1.lemma4, `ReadL1.lemma5, `ReadL1.lemma6, `ReadL1.norm_readOp_le] do
    -- `collectAxioms` returns `[]` for a name that does not exist, so check existence first.
    if (env.find? n).isNone then throwError m!"{n} missing"
    let axs ← collectAxioms n
    let extra := axs.filter fun a ↦ !standard.contains a
    unless extra.isEmpty do throwError m!"{n} uses axioms outside the standard three: {extra}"
  let fc ← collectAxioms `InvariantSubspaceProblem.Invariant_subspace_problem_l1
  unless fc.contains ``sorryAx do
    throwError "control failed: Formal Conjectures' statement no longer shows sorryAx"
  logInfo m!"audit passed: statement identical ({ours.type}); standard axioms only; control ok"

/-- The statement, restated by hand, is proved by the headline theorem. -/
example : ∃ (T : (lp (fun (_ : ℕ) => ℂ) 1) →L[ℂ] (lp (fun (_ : ℕ) => ℂ) 1)),
    IsEmpty (InvariantSubspaceProblem.ClosedInvariantSubspace T) :=
  ReadL1.invariant_subspace_problem_l1

open ReadL1 Polynomial in
/-- The operator is not zero: it sends `δ₀ = x⁰` to the coordinates of `x¹`, which are not zero
since they read back as the polynomial `X`. -/
example : readOp theorem7Hyp_dRead.toGrowthHyp ≠ 0 := by
  intro h0
  have h1 : toL1 (xPow dRead 1) = 0 := by
    have := congrArg (fun T ↦ T (δ 0)) h0
    simpa [readOp_single, shiftImage] using this
  have h2 : xPow dRead 1 = 0 := by
    ext k
    have := congrArg (fun x : L1 ↦ x k) h1
    simpa [toL1_apply] using this
  have h3 := fromCoord_xPow theorem7Hyp_dRead.toPartitionHyp 1
  rw [h2, map_zero, pow_one] at h3
  exact X_ne_zero h3.symm
