Set Warnings "-notation-overridden".

Require Import Coq.Bool.Bool.
Require Import Coq.Lists.List.
Require Import Coq.FSets.FMapPositive.

Module Import MP := FMapPositive.
Module M := MP.PositiveMap.

Require Import Category.Lib.
Require Import Category.Theory.Category.

Require Import Solver.Lib.
Require Import Solver.Expr.
Require Import Solver.Denote.
Require Import Solver.Normal.

Generalizable All Variables.

Section Sound.

Context {C : Category}.

Variable objs : obj_idx -> C.
Variable arrmap : M.t (∃ x y, objs x ~{C}~> objs y).

Definition arrs (a : arr_idx) := M.find a arrmap.

Ltac destruct_arrows :=
  lazymatch goal with
  | [ H : context[match Solver.Normal.arrs objs arrmap ?t with _ => _ end] |- _ ] =>
    destruct (Solver.Normal.arrs objs arrmap t) as [[? []]|] eqn:?;
    [|discriminate + contradiction]
  | [ H : context[match arrowsD_work ?objs ?arrs ?o ?t with _ => _ end] |- _ ] =>
    destruct (arrowsD_work objs arrmap o t) as [[]|] eqn:?;
    [|discriminate + contradiction]
  | [ H : context[match termD_work ?objs ?arrs ?o ?t with _ => _ end] |- _ ] =>
    destruct (termD_work objs arrmap o t) as [[]|] eqn:?;
    [|discriminate + contradiction]
  | [ H : Some _ = Some _ |- _ ] => inversion H; subst; clear H
  | [ H : (?x; ?f) = (?y; ?g) |- _ ] => inversion H; subst
  end;
  try (equalities; let n := numgoals in guard n < 2);
  simpl_eq.

Theorem arrowsD_compose {xs ys dom cod f} :
  arrowsD_work objs arrmap dom (xs ++ ys) = Some (cod; f) ->
  ∃ mid g h, f ≈ g ∘ h ∧
    arrowsD_work objs arrmap mid xs = Some (cod; g) ∧
    arrowsD_work objs arrmap dom ys = Some (mid; h).
Proof.
  intros.
  generalize dependent ys.
  generalize dependent cod.
  generalize dependent dom.
  induction xs; simpl; intros.
    simpl in H.
    exists cod, id, f.
    split; cat.
  destruct_arrows.
  destruct ys eqn:?.
    exists dom, f, id.
    rewrite app_nil_r in H.
    split; cat.
    assert (
      match arrowsD_work objs arrmap dom (xs ++ a0 :: l) with
      | Some s =>
        match s with
        | (mid; g) =>
          match BinPos.Pos.eq_dec mid x with
          | left emid =>
            Some (x0; (h ∘ match emid with eq_refl => g end))
          | right _ =>
            @None (@sigT obj_idx
                         (fun cod : obj_idx =>
                            @hom C (objs dom) (objs cod)))
          end
        end
      | None => None
      end = Some (existT _ cod f)) by (destruct xs; auto).
  clear H.
  destruct_arrows.
  specialize (IHxs _ _ _ _ Heqo0).
  destruct_arrows.
  destruct xs.
  - simpl in a2.
    inversion a2; subst.
    exists _, h, x2.
    split.
    + rewrite a1.
      rewrite <- (Eqdep_dec.inj_pair2_eq_dec _ Eq_eq_dec _ _ _ _ H1).
      cat.
    + split.
      * equalities.
      * simpl in b0.
        destruct_arrows.
  - exists _, (h ∘ x1), x2.
    split.
    + rewrite a1; cat.
    + split.
      * rewrite a2.
        equalities.
      * simpl in b0.
        destruct_arrows.
Qed.

Theorem arrowsD_sound {p dom cod f} :
  arrowsD objs arrmap dom cod (arrows p) = Some f ->
  ∃ f', f ≈ f' ∧ termD objs arrmap dom cod p = Some f'.
Proof.
  unfold termD, arrowsD.
  generalize dependent dom.
  generalize dependent cod.
  induction p; simpl; intros; repeat equalities; simpl_eq.
  - firstorder.
  - firstorder.
  - destruct_arrows.
    pose proof (arrowsD_compose Heqo).
    equalities.
    specialize (IHp1 cod x x0).
    rewrite a0 in IHp1.
    rewrite Eq_eq_dec_refl in IHp1.
    specialize (IHp1 (reflexivity _)).
    destruct IHp1, p.
    specialize (IHp2 x dom x1).
    rewrite b0 in IHp2.
    rewrite Eq_eq_dec_refl in IHp2.
    specialize (IHp2 (reflexivity _)).
    destruct IHp2, p.
    exists (x2 ∘ x3).
    split.
      rewrite <- e, <- e1, <- a.
      now inversion_clear H.
    repeat destruct_arrows.
    rewrite Heqo1.
    equalities.
Qed.

Theorem arrowsD_compose_r {xs ys dom mid cod g h} :
  arrowsD_work objs arrmap mid xs = Some (cod; g) ->
  arrowsD_work objs arrmap dom ys = Some (mid; h) ->
  ∃ f, f ≈ g ∘ h ∧
    arrowsD_work objs arrmap dom (xs ++ ys) = Some (cod; f).
Proof.
  intros.
  generalize dependent ys.
  generalize dependent cod.
  generalize dependent dom.
  induction xs; simpl; intros.
    destruct_arrows; cat.
  repeat destruct_arrows.
  destruct (arrowsD_work objs arrmap mid xs) eqn:?;
  [|destruct xs; [|discriminate]; equalities].
  destruct s, xs; equalities.
    (* jww (2017-08-07): I have the feeling this branch of the proof is
       longer than it needs to be. *)
    inversion H; subst.
    simpl in Heqo0.
    inversion Heqo0; subst.
    specialize (IHxs dom h x1 h1 eq_refl _ H0).
    equalities.
    simpl in *.
    destruct ys; simpl in *.
      inversion H0; subst.
      equalities'; auto.
      equalities'; auto.
      rewrite <- (Eqdep_dec.inj_pair2_eq_dec _ Eq_eq_dec _ _ _ _ H5).
      exists h0.
      simpl; cat.
    destruct_arrows.
    destruct ys.
      equalities.
      inversion H0; subst.
      equalities'; auto.
      rewrite Eq_eq_dec_refl.
      exists (h0 ∘ h).
      simpl; cat.
      rewrite (Eqdep_dec.inj_pair2_eq_dec _ Eq_eq_dec _ _ _ _ H5).
      reflexivity.
    destruct_arrows.
    equalities'; auto.
    destruct (Eq_eq_dec x3 x0); [|discriminate]; subst.
    inversion H0; subst.
    equalities'; auto.
    rewrite Eq_eq_dec_refl.
    exists (h0 ∘ (h2 ∘ h3)).
    simpl; cat.
    rewrite (Eqdep_dec.inj_pair2_eq_dec _ Eq_eq_dec _ _ _ _ H5).
    reflexivity.
  destruct (IHxs dom h x h1 eq_refl _ H0); clear IHxs.
  destruct p.
  inversion H; simpl in *; subst.
  destruct_arrows.
  destruct (xs ++ ys) eqn:?.
    equalities'; auto.
    destruct (Eq_eq_dec x0 dom); [|discriminate].
    destruct e1.
    inversion e0; subst.
    equalities'; auto.
    rewrite Eq_eq_dec_refl.
    exists (h0 ∘ h2).
    split; cat.
    rewrite <- comp_assoc.
    rewrite <- e.
    now rewrite (Eqdep_dec.inj_pair2_eq_dec _ Eq_eq_dec _ _ _ _ H4).
  destruct_arrows; equalities.
  inversion e0; subst.
  equalities'; auto.
  rewrite Eq_eq_dec_refl.
  exists (h0 ∘ (h2 ∘ h3)).
  simpl; cat.
  rewrite <- comp_assoc.
  rewrite (Eqdep_dec.inj_pair2_eq_dec _ Eq_eq_dec _ _ _ _ H4).
  now rewrite <- e.
Qed.

Theorem arrowsD_sound_r {p dom cod f} :
  termD objs arrmap dom cod p = Some f ->
  ∃ f', f ≈ f' ∧ arrowsD objs arrmap dom cod (arrows p) = Some f'.
Proof.
  unfold termD, arrowsD.
  generalize dependent dom.
  generalize dependent cod.
  induction p; simpl; intros; repeat equalities; simpl_eq.
  - firstorder.
  - firstorder.
  - repeat destruct_arrows.
    specialize (IHp1 cod x h0).
    rewrite Heqo0 in IHp1.
    rewrite Eq_eq_dec_refl in IHp1.
    specialize (IHp1 (reflexivity _)).
    destruct IHp1, p.
    specialize (IHp2 x dom h).
    rewrite Heqo in IHp2.
    rewrite Eq_eq_dec_refl in IHp2.
    specialize (IHp2 (reflexivity _)).
    destruct IHp2, p.
    repeat destruct_arrows.
    destruct (arrowsD_compose_r Heqo2 Heqo1), p.
    exists x2.
    split.
      now rewrite e, e1, e0.
    rewrite e2.
    equalities'; auto.
    now rewrite Eq_eq_dec_refl.
Qed.

Lemma arrows_decide {x y f f' g g'} :
  @termD C objs arrmap x y f = Some f' ->
  @termD C objs arrmap x y g = Some g' ->
  list_beq Eq_eqb (arrows f) (arrows g) = true ->
  f' ≈ g'.
Proof.
  intros.
  destruct (arrowsD_sound_r H), p.
  destruct (arrowsD_sound_r H0), p.
  apply list_beq_eq in H1.
    rewrite H1 in e0.
    rewrite e, e1.
    rewrite e0 in e2.
    now inversion_clear e2.
  apply Eq_eqb_eq.
Qed.

Lemma arrowsD_apply dom cod (f g : Term) :
  list_beq Eq_eqb (arrows f) (arrows g) = true ->
  arrowsD objs arrmap dom cod (arrows f) ||| false = true ->
  arrowsD objs arrmap dom cod (arrows f) = arrowsD objs arrmap dom cod (arrows g) ->
  termD objs arrmap dom cod f ≈ termD objs arrmap dom cod g.
Proof.
  intros.
  destruct (arrowsD objs arrmap dom cod (arrows f)) eqn:?; [|discriminate].
  destruct (arrowsD_sound Heqo), p.
  rewrite e0; clear e0.
  red.
  symmetry in H1.
  apply arrowsD_sound in H1.
  equalities.
  rewrite e1.
  rewrite <- e0, <- e.
  reflexivity.
Qed.

Lemma exprAD_sound (e : Expr) : exprAD objs arrmap e ↔ exprD objs arrmap e.
Proof.
  induction e; simpl; split; intros; firstorder auto.
  - destruct (arrowsD objs arrmap x y (arrows f)) eqn:?.
      destruct (arrowsD objs arrmap x y (arrows g)) eqn:?; [|contradiction].
      destruct (arrowsD_sound Heqo), p.
      destruct (arrowsD_sound Heqo0) ,p.
      now rewrite e0, e2, <- e, <- e1.
    destruct (arrowsD objs arrmap x y (arrows g)) eqn:?; [contradiction|].
    destruct (termD objs arrmap x y f) eqn:?.
      destruct (arrowsD_sound_r Heqo1), p.
      rewrite Heqo in e0.
      discriminate.
    destruct (termD objs arrmap x y g) eqn:?; auto.
    destruct (arrowsD_sound_r Heqo2), p.
    rewrite Heqo0 in e0.
    discriminate.
  - destruct (termD objs arrmap x y f) eqn:?.
      destruct (termD objs arrmap x y g) eqn:?; [|contradiction].
      destruct (arrowsD_sound_r Heqo), p.
      destruct (arrowsD_sound_r Heqo0), p.
      now rewrite e0, e2, <- e, <- e1.
    destruct (termD objs arrmap x y g) eqn:?; [contradiction|].
    destruct (arrowsD objs arrmap x y (arrows f)) eqn:?.
      destruct (arrowsD_sound Heqo1), p.
      rewrite Heqo in e0.
      discriminate.
    destruct (arrowsD objs arrmap x y (arrows g)) eqn:?; auto.
    destruct (arrowsD_sound Heqo2), p.
    rewrite Heqo0 in e0.
    discriminate.
Qed.

End Sound.
