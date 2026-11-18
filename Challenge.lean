/-
Copyright 2025 The Formal Conjectures Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-/
module

public import Mathlib

/-!
# Read's theorem on ℓ¹

There is a bounded operator on `ℓ¹(ℕ, ℂ)` with no closed invariant subspace other than `0` and
the whole space (C. J. Read, Bull. London Math. Soc. 17 (1985); the first counterexample on a
Banach space is P. Enflo's, Acta Math. 158 (1987)). Formal Conjectures marks this
`research solved`.

The structure `ClosedInvariantSubspace` and the statement `Invariant_subspace_problem_l1` below are
copied verbatim from Formal Conjectures (`google-deepmind/formal-conjectures`, commit
`40a8592cb6f7e96cb9a8275d96bb3e013feeb1dc`, file
`FormalConjectures/Wikipedia/InvariantSubspaceProblem.lean`), with the `category` and `AMS`
attributes removed. The statement keeps Formal Conjectures' name.
`scripts/check-fc-match.py` checks that text, and allows no other change.
-/

@[expose] public section

namespace InvariantSubspaceProblem

variable {H : Type*} [NormedAddCommGroup H]

/-- `ClosedInvariantSubspace T` is the type of non-trivial (different from `H` and `{0}`) closed
subspaces of a complex vector space `H` that are invariant under the action of linear map `T`. -/
structure ClosedInvariantSubspace [Module ℂ H] (T : H →L[ℂ] H) where
  toSubspace : Submodule ℂ H
  ne_bot : toSubspace ≠ ⊥
  ne_top : toSubspace ≠ ⊤
  is_closed : IsClosed (toSubspace : Set H)
  is_fixed : toSubspace.map T.toLinearMap ≤ toSubspace

/--
There exists a bounded linear operator `T` on the l1 space `(lp (fun (_ : ℕ) => ℂ) 1))` without
non-trivial closed `T`-invariant subspace [Read 1985](https://doi.org/10.1112/blms/17.4.305), see
also the first counterexample by Enflo [Enflo 1987](https://doi.org/10.1007%2FBF02392260), submitted
in 1981. -/
theorem Invariant_subspace_problem_l1 :
    ∃ (T : (lp (fun (_ : ℕ) => ℂ) 1) →L[ℂ] (lp (fun (_ : ℕ) => ℂ) 1)),
    IsEmpty (ClosedInvariantSubspace T) := by
  sorry

end InvariantSubspaceProblem
