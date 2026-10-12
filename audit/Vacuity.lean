/-
Copyright (c) 2026 Zayn Blore. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Zayn Blore
-/
import ReadL1

/-!
Audit: every declaration in `ReadL1` is used by another one, except the headline result the
project exists to state. Any unused declaration is an error, so `lake env lean` exits nonzero.
-/

open Lean Elab Command in
run_cmd do
  let env ← getEnv
  -- Lean generates equation lemmas (`xPow.eq_1`, `eq_def`, `eq_unfold`), congruence lemmas
  -- (`congr_simp`) and, for structures and inductives, constructors, projections, recursors,
  -- `ext`/`injEq` lemmas and per-constructor eliminators (`Kind.J.elim`), none written by hand.
  -- They are recognised by name only, so these suffixes are reserved: never use them for a
  -- hand-written declaration.
  let generated : List String :=
    ["congr_simp", "eq_def", "eq_unfold", "mk", "injEq", "inj", "ext", "ext_iff", "rec",
      "recOn", "casesOn", "noConfusion", "noConfusionType", "ctorIdx", "toCtorIdx", "sizeOf_spec",
      "brecOn", "below", "binductionOn", "ibelow", "elim"]
  let isGenerated : Name → Bool
    | .str _ s => generated.contains s ||
        (s.startsWith "eq_" && s.length > 3 && (s.toList.drop 3).all Char.isDigit)
    | _ => false
  let ours := env.constants.fold (fun (acc : Array Name) n ci ↦
    if (`ReadL1).isPrefixOf n && !n.isInternal && !isGenerated n &&
        !(ci matches .ctorInfo _ | .recInfo _ | .inductInfo _) then acc.push n else acc) #[]
  let headlines : List Name := [`ReadL1.invariant_subspace_problem_l1]
  let mut used : NameSet := {}
  for n in env.constants.toList.map (·.1) do
    if (`ReadL1).isPrefixOf n then
      if let some ci := env.find? n then
        let v := match ci with
          | .thmInfo t => t.value.getUsedConstants
          | .defnInfo d => d.value.getUsedConstants
          | _ => #[]
        for m in ci.type.getUsedConstants ++ v do
          if m != n then used := used.insert m
  let unused := ours.filter fun n ↦ !used.contains n && !headlines.contains n
  unless unused.isEmpty do throwError m!"unused declarations: {unused.toList}"
  unless ours.size ≥ 200 do throwError m!"only {ours.size} declarations found; wrong prefix?"
  logInfo m!"vacuity audit passed: {ours.size} declarations, none unused apart from the headline"
