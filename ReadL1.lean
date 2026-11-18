/-
Copyright (c) 2026 Zayn Blore. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Zayn Blore
-/
module

public import ReadL1.Basis
public import ReadL1.Coord
public import ReadL1.Cyclic
public import ReadL1.Defs
public import ReadL1.Explicit
public import ReadL1.FormalTarget
public import ReadL1.Growth
public import ReadL1.Inverse
public import ReadL1.L1Lift
public import ReadL1.Lemma1
public import ReadL1.Lemma2
public import ReadL1.Lemma4
public import ReadL1.Lemma4I
public import ReadL1.Lemma4J
public import ReadL1.Lemma4K
public import ReadL1.Lemma4L
public import ReadL1.Lemma5
public import ReadL1.Lemma5Coeff
public import ReadL1.Lemma5Window
public import ReadL1.Lemma6
public import ReadL1.Main
public import ReadL1.Norm
public import ReadL1.Operator
public import ReadL1.Partition
public import ReadL1.Poly
public import ReadL1.PolyNorm
public import ReadL1.Projection
public import ReadL1.QPoly
public import ReadL1.Theorem7
public import ReadL1.Theorem7Prep

/-!
# Read's counterexample on ℓ¹, for Formal Conjectures

A proof of `InvariantSubspaceProblem.Invariant_subspace_problem_l1` (`ReadL1.FormalTarget`, from
`ReadL1.invariant_subspace_problem_l1` in `ReadL1.Main`): an operator
on ℓ¹ with no nontrivial closed invariant subspace, following W. Śliwa, Rocky Mountain J. Math. 40
(2010).
-/

