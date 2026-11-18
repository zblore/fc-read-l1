/-
Copyright (c) 2026 Zayn Blore. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Zayn Blore
-/
module

public import ReadL1.Main

/-!
# Formal Conjectures' statement

`Invariant_subspace_problem_l1` from `FormalConjectures/Wikipedia/InvariantSubspaceProblem.lean`,
under Formal Conjectures' name, proved by `ReadL1.invariant_subspace_problem_l1`. This is the
declaration that Palomar's Comparator checks against `Challenge.lean`.
-/

@[expose] public section

namespace InvariantSubspaceProblem

/--
There exists a bounded linear operator `T` on the l1 space `(lp (fun (_ : ℕ) => ℂ) 1))` without
non-trivial closed `T`-invariant subspace [Read 1985](https://doi.org/10.1112/blms/17.4.305), see
also the first counterexample by Enflo [Enflo 1987](https://doi.org/10.1007%2FBF02392260), submitted
in 1981. -/
theorem Invariant_subspace_problem_l1 :
    ∃ (T : (lp (fun (_ : ℕ) => ℂ) 1) →L[ℂ] (lp (fun (_ : ℕ) => ℂ) 1)),
    IsEmpty (ClosedInvariantSubspace T) :=
  ReadL1.invariant_subspace_problem_l1

end InvariantSubspaceProblem
