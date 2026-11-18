/-
Copyright (c) 2026 Zayn Blore. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Zayn Blore
-/
module

public import ReadL1

/-!
# Controls

* The axiom audit would catch a `sorry`: `#print axioms` reports `sorryAx` for an unproved
  statement.
* The statement, restated by hand, is proved by the headline theorem, and Formal Conjectures' name
  and the `ReadL1` name have the same statement.
* The operator is not zero: it sends `δ₀ = x⁰` to the coordinates of `x¹`, which are not zero since
  they read back as the polynomial `X`. So the theorem is not met by the zero operator on a space
  that is somehow trivial.
-/

public theorem unproved : ∃ (T : (lp (fun (_ : ℕ) => ℂ) 1) →L[ℂ] (lp (fun (_ : ℕ) => ℂ) 1)),
    IsEmpty (InvariantSubspaceProblem.ClosedInvariantSubspace T) := by
  sorry

/-- info: 'unproved' depends on axioms: [propext, sorryAx, Classical.choice, Quot.sound] -/
#guard_msgs in
#print axioms unproved

/-- The statement, restated by hand, is proved by the headline theorem. -/
example : ∃ (T : (lp (fun (_ : ℕ) => ℂ) 1) →L[ℂ] (lp (fun (_ : ℕ) => ℂ) 1)),
    IsEmpty (InvariantSubspaceProblem.ClosedInvariantSubspace T) :=
  ReadL1.invariant_subspace_problem_l1

example : type_of% @InvariantSubspaceProblem.Invariant_subspace_problem_l1 =
    type_of% @ReadL1.invariant_subspace_problem_l1 :=
  rfl

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
