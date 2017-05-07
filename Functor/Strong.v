Set Warnings "-notation-overridden".

Require Import Category.Lib.
Require Export Category.Theory.Functor.
Require Export Category.Functor.Bifunctor.
Require Export Category.Structure.Cartesian.
Require Export Category.Structure.Monoidal.
Require Export Category.Instance.Cat.
Require Export Category.Instance.Cat.Cartesian.

Generalizable All Variables.
Set Primitive Projections.
Set Universe Polymorphism.

Class StrongFunctor `{C : Category} `{@Monoidal C} (F : C ⟶ C) := {
  strength_nat : (* (⨂) ○ second F ⟹ F ○ (⨂) *)
    (@Compose (C ∏ C) (C ∏ C) C (@tensor C _) (second F))
      ~{[C ∏ C, C]}~>
    (@Compose (C ∏ C) C C F (@tensor C _));

  strength {X Y} : X ⨂ F Y ~> F (X ⨂ Y) := transform[strength_nat] (X, Y);

  strength_id_left {X} :
    fmap[F] (to unit_left) ∘ strength ≈ to (@unit_left _ _ (F X));
  strength_assoc {X Y Z} :
    strength ∘ bimap id strength ∘ to (@tensor_assoc _ _ X Y (F Z))
      ≈ fmap[F] (to (@tensor_assoc _ _ X Y Z)) ∘ strength
}.

(*
Section Strong.

Context `{C : Category}.
Context `{@Monoidal C}.
Context `{F : C ⟶ C}.
Context `{@StrongFunctor C _ F}.

Lemma strength_id_left {X} :
  fmap[F] (to unit_left) ∘ strength ≈ to (@unit_left _ _ (F X)).
Proof.
  unfold strength.
  destruct H0; simpl in *; clear H0 strength0;
  destruct strength_nat0; simpl in *.

  strength_naturality {X Y Z} :
    strength ∘ bimap id strength ∘ to (@tensor_assoc _ _ X Y (F Z))
      ≈ fmap[F] (to (@tensor_assoc _ _ X Y Z)) ∘ strength
*)

Class RightStrongFunctor `{C : Category} `{@Monoidal C} (F : C ⟶ C) := {
  rstrength_nat : (* (⨂) ○ first F ⟹ F ○ (⨂) *)
    (@Compose (C × C) (C × C) C (@tensor C _) (first F))
      ~{[C × C, C]}~>
    (@Compose (C × C) C C F (@tensor C _));

  rstrength {X Y} : F X ⨂ Y ~> F (X ⨂ Y) := transform[rstrength_nat] (X, Y);

  rrstrength_id_right {X} :
    fmap[F] (to unit_right) ∘ rstrength ≈ to (@unit_right _ _ (F X));
  rstrength_assoc {X Y Z} :
    rstrength ∘ bimap rstrength id ∘ from (@tensor_assoc _ _ (F X) Y Z)
      ≈ fmap[F] (from (@tensor_assoc _ _ X Y Z)) ∘ rstrength
}.

Section Strong.

Context `{C : Category}.
Context `{@Monoidal C}.
Context `{F : C ⟶ C}.

Program Instance Id_Strong : StrongFunctor Id[C] := {
  strength_nat := {| transform := fun p => _ |}
}.
Next Obligation.
  exact id.
Defined.
Next Obligation.
  unfold bimap; cat.
Qed.

Local Obligation Tactic := program_simpl.

Global Program Instance Compose_StrongFunctor (F G : C ⟶ C)
       `{@StrongFunctor C _ F}
       `{@StrongFunctor C _ G} :
  `{@StrongFunctor C _ (F ○ G)} := {
  strength_nat := {| transform := fun _ => fmap[F] strength ∘ strength |}
}.
Next Obligation.
  destruct H0, H1; simpl in *.
  unfold strength in *.
  unfold strength_nat in *.
  unfold strength0, strength1 in *.
  destruct strength_nat0, strength_nat1; simpl in *.
  rewrite !comp_assoc.
  rewrite <- fmap_comp.
  rewrite (natural_transformation0 (o1, o2) (o, o0) (h, h0)).
  rewrite fmap_comp.
  rewrite <- !comp_assoc.
  apply compose_respects; [reflexivity|].
  apply (natural_transformation (o1, G o2) (o, G o0) (h, fmap[G] h0)).
Qed.
Next Obligation.
  destruct H0, H1; simpl in *.
  unfold strength in *.
  unfold strength_nat in *.
  unfold strength0, strength1 in *.
  destruct strength_nat0, strength_nat1; simpl in *.
  rewrite comp_assoc.
  rewrite <- fmap_comp.
  rewrite strength_id_left1.
  apply strength_id_left0.
Qed.
Next Obligation.
  destruct H0, H1; simpl in *.
  unfold strength in *.
  unfold strength_nat in *.
  unfold strength0, strength1 in *.
  destruct strength_nat0, strength_nat1; simpl in *.
  rewrite comp_assoc.
  rewrite <- fmap_comp.
  rewrite <- strength_assoc1.
  rewrite !fmap_comp.
  rewrite <- !comp_assoc.
  rewrite <- strength_assoc0.
  apply compose_respects; [reflexivity|].
  rewrite !comp_assoc.
  rewrite (natural_transformation (X, Y ⨂ G Z) (X, G (Y ⨂ Z))
                                  (id[X], transform0 (Y, Z))).
  unfold bimap; simpl.
  rewrite <- !comp_assoc.
  apply compose_respects; [reflexivity|].
  rewrite comp_assoc.
  rewrite <- fmap_comp; simpl.
  apply compose_respects; [|reflexivity].
  apply fmap_respects.
  split; simpl; cat.
Qed.

End Strong.