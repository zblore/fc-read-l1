/-
Copyright (c) 2026 Zayn Blore. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Zayn Blore
-/
module

public import ReadL1

/-!
# Axioms of the main results

Fails if the main result, or a key lemma, comes to depend on anything beyond Lean's three
standard axioms.
-/

/--
info: 'InvariantSubspaceProblem.Invariant_subspace_problem_l1' depends on axioms:
  [propext, Classical.choice, Quot.sound]
-/
#guard_msgs (whitespace := lax) in
#print axioms InvariantSubspaceProblem.Invariant_subspace_problem_l1

/--
info: 'ReadL1.invariant_subspace_problem_l1' depends on axioms:
  [propext, Classical.choice, Quot.sound]
-/
#guard_msgs (whitespace := lax) in
#print axioms ReadL1.invariant_subspace_problem_l1

/--
info: 'ReadL1.theorem7' depends on axioms:
  [propext, Classical.choice, Quot.sound]
-/
#guard_msgs (whitespace := lax) in
#print axioms ReadL1.theorem7

/--
info: 'ReadL1.theorem7Hyp_dRead' depends on axioms:
  [propext, Classical.choice, Quot.sound]
-/
#guard_msgs (whitespace := lax) in
#print axioms ReadL1.theorem7Hyp_dRead

/--
info: 'ReadL1.lemma4' depends on axioms:
  [propext, Classical.choice, Quot.sound]
-/
#guard_msgs (whitespace := lax) in
#print axioms ReadL1.lemma4

/--
info: 'ReadL1.lemma5' depends on axioms:
  [propext, Classical.choice, Quot.sound]
-/
#guard_msgs (whitespace := lax) in
#print axioms ReadL1.lemma5

/--
info: 'ReadL1.lemma6' depends on axioms:
  [propext, Classical.choice, Quot.sound]
-/
#guard_msgs (whitespace := lax) in
#print axioms ReadL1.lemma6

/--
info: 'ReadL1.norm_readOp_le' depends on axioms:
  [propext, Classical.choice, Quot.sound]
-/
#guard_msgs (whitespace := lax) in
#print axioms ReadL1.norm_readOp_le
