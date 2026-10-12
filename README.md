# Read's operator on ℓ¹ in Lean

A Lean 4 proof that there is a bounded operator on ℓ¹ with no nontrivial closed invariant subspace. It proves `Invariant_subspace_problem_l1` from the invariant subspace problem file in Google DeepMind's [Formal Conjectures](https://github.com/google-deepmind/formal-conjectures) against their own definitions.

## The result

The invariant subspace problem asks whether every bounded operator T on a Banach space has a closed subspace, other than 0 and the whole space, that T maps into itself. For general Banach spaces the answer is no. Enflo found the first counterexample, and in 1985 Read gave one on the sequence space ℓ¹ itself.

This repository formalises the explicit version of Read's example due to Wiesław Śliwa ("An explicit example concerning the invariant subspace problem for Banach spaces", Rocky Mountain J. Math. 40 (2010) 627–641). Earlier proofs only work for "sufficiently rapidly increasing" sequences. Śliwa writes down concrete growth conditions instead, and proves every lemma, which is what makes a formal proof practical.

I found no earlier formal proof of Read's theorem.

## The proof

Śliwa builds a basis of the polynomials from a fast-growing integer sequence, lets T be multiplication by x, and shows that the vector 1 can be approximated by p(T)e for every nonzero e. The files, all in `ReadL1/`, follow his paper.

- `Partition.lean`, `Basis.lean`: the blocks J, I, L, K that cut up the indices, the basis fᵢ, and the operator on finite sequences. `T₀_xPow` proves T is multiplication by x.
- `Growth.lean`: the inequalities between the sequences that the proofs use, collected as hypotheses (`GrowthHyp`).
- `Norm.lean`, `Lemma1.lean`, `Lemma2.lean`, `L1Lift.lean`, `Operator.lean`: Lemmas 1 and 2, and the bounded operator on ℓ¹ with ‖T‖ ≤ 8.
- `Projection.lean`, `Lemma4J/I/L/K.lean`, `Lemma4.lean`: the projection Qₘ and Lemma 4, ‖Tˢ − TˢQₘ‖ ≤ α, where α = 8 is Śliwa's constant.
- `PolyNorm.lean`, `Inverse.lean`, `Lemma6.lean`: the coefficient norm and Lemma 6, an approximate inverse of a polynomial with a bounded norm.
- `Coord.lean`, `QPoly.lean`, `Lemma5Coeff.lean`, `Lemma5Window.lean`, `Lemma5.lean`: Qₘe as a polynomial, and Lemma 5.
- `Theorem7Prep.lean`, `Theorem7.lean`, `Cyclic.lean`: Theorem 7, that T has no nontrivial closed invariant subspace.
- `Explicit.lean`: a concrete sequence satisfying every growth condition. Each term after the first is a power 8^{2s}, so the square roots in Śliwa's conditions are exact.
- `Main.lean`: `ReadL1.invariant_subspace_problem_l1`.

Where the formalisation departs from the paper:

- α is fixed at 8 (Śliwa allows any α ≥ 8).
- A few of Śliwa's constants are rounded in the paper; the exact ones are used here.
- The bound |Qₘe| ≤ Aₘ comes from bounding each |fₗ| directly rather than through his √Aₘ · √Aₘ. The resulting bound is the same.

The statement is the same term as Formal Conjectures' `InvariantSubspaceProblem.Invariant_subspace_problem_l1`. The proof uses only `propext`, `Classical.choice` and `Quot.sound`.

## Building

It needs Lean v4.33.1 and depends on Formal Conjectures at commit `40a8592c`.

```
lake exe cache get
lake build
```

A fresh build first compiles the parts of Formal Conjectures it imports. On a machine with limited memory set `LEAN_NUM_THREADS` to a small number first.

To rerun the checks, one at a time:

```
lake env lean audit/Audit.lean
lake env lean audit/Vacuity.lean
python audit/lexical.py
```

`Audit.lean` checks that the statement is identical to Formal Conjectures' and that only the standard axioms are used, and that the operator is not zero. `Vacuity.lean` checks that every declaration is used. `lexical.py` checks the docstrings, imports and formatting.

## How it was made

I used Claude Code to draft the Lean.

## About

I'm Zayn Blore. My main project is [csd-lean4](https://github.com/zblore/csd-lean4), the Lean library behind my work on Constraint-Surface Dynamics.
