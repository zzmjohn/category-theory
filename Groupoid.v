Require Import Lib.
Require Export Category.
Require Export Iso.

Generalizable All Variables.
Set Primitive Projections.
Set Universe Polymorphism.
Set Shrink Obligations.

Section Groupoid.

Context `{cat : Category C}.

(* A Groupoid is a category where all the morphisms are isomorphisms, and
   morphism equivalence is equivalence of isomorphisms. *)
Program Instance Groupoid : Category C := {
  hom     := @isomorphic C _;
  id      := fun _ => _;
  compose := fun _ _ _ => _;
  eqv     := @isomorphic_eqv C _
}.
Next Obligation.
  reflexivity.                  (* identity is reflexivity *)
Defined.
Obligation 2.
  transitivity H0; assumption.  (* composition is transitivity *)
Defined.
Obligation 3.
  unfold Groupoid_obligation_2.
  intros ??????.
  econstructor.
  split; apply proof_irrelevance.
  Unshelve.
  - destruct x, y, x0, y0, H, H0; simpl in *.
    rewrite iso_to_eqv.
    rewrite iso_to_eqv0.
    reflexivity.
  - destruct x, y, x0, y0, H, H0; simpl in *.
    rewrite iso_from_eqv.
    rewrite iso_from_eqv0.
    reflexivity.
Qed.
Obligation 4.
  unfold Groupoid_obligation_1.
  unfold Groupoid_obligation_2.
  econstructor.
  split; apply proof_irrelevance.
  Unshelve.
  - destruct f; simpl; cat.
  - destruct f; simpl; cat.
Qed.
Obligation 5.
  unfold Groupoid_obligation_1.
  unfold Groupoid_obligation_2.
  econstructor.
  split; apply proof_irrelevance.
  Unshelve.
  - destruct f; simpl; cat.
  - destruct f; simpl; cat.
Qed.
Obligation 6.
  unfold Groupoid_obligation_1.
  unfold Groupoid_obligation_2.
  econstructor.
  split; apply proof_irrelevance.
  Unshelve.
  - destruct f, g, h; simpl.
    rewrite comp_assoc; reflexivity.
  - destruct f, g, h; simpl.
    rewrite comp_assoc; reflexivity.
Qed.

End Groupoid.
