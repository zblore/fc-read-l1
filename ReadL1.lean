/-
Copyright (c) 2026 Zayn Blore. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Zayn Blore
-/
import ReadL1.Basis
import ReadL1.Coord
import ReadL1.Cyclic
import ReadL1.Explicit
import ReadL1.Growth
import ReadL1.Inverse
import ReadL1.L1Lift
import ReadL1.Lemma1
import ReadL1.Lemma2
import ReadL1.Lemma4
import ReadL1.Lemma4I
import ReadL1.Lemma4J
import ReadL1.Lemma4K
import ReadL1.Lemma4L
import ReadL1.Lemma5
import ReadL1.Lemma5Coeff
import ReadL1.Lemma5Window
import ReadL1.Lemma6
import ReadL1.Main
import ReadL1.Norm
import ReadL1.Operator
import ReadL1.Partition
import ReadL1.Poly
import ReadL1.PolyNorm
import ReadL1.Projection
import ReadL1.QPoly
import ReadL1.Theorem7
import ReadL1.Theorem7Prep

/-!
# Read's counterexample on ℓ¹, for Formal Conjectures

A proof of `InvariantSubspaceProblem.Invariant_subspace_problem_l1` (`ReadL1.Main`): an operator
on ℓ¹ with no nontrivial closed invariant subspace, following W. Śliwa, Rocky Mountain J. Math. 40
(2010).
-/

