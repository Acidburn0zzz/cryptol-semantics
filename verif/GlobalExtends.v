Require Import List.
Import ListNotations.
Require Import String.

(* Borrow from CompCert *)
Require Import Coqlib.
Require Import Bitvectors.

Require Import AST.
Require Import Semantics.
Require Import Utils.
Require Import Builtins.
Require Import BuiltinSem.
Require Import BuiltinSyntax.
Require Import Values.        
Require Import Eager.
Require Import Bitstream.
Require Import Lib.
Require Import EagerEvalInd.

Definition global_extends (ge ge' : genv) : Prop :=
  forall id v,
    ge id = Some v ->
    ge' id = Some v.


Lemma global_extends_refl :
  forall GE,
    global_extends GE GE.
Proof.
  intros.
  unfold global_extends. auto.
Qed.


Definition name_irrel {A : Type} (E : ident -> option A) : Prop :=
  forall id id',
    if ident_eq id id' then E id = E id' else True.

Lemma global_extends_extend_r :
  forall ge ge',
    global_extends ge ge' ->
    name_irrel ge ->
    forall id exp,
      ge id = None ->
      global_extends ge (extend ge' id exp).
Proof.
  intros.
  unfold global_extends in *.
  intros.
  unfold extend. unfold name_irrel in *.
  specialize (H0 id0 id).
  destruct (ident_eq id0 id).
  congruence. eapply H; eauto.
Qed.

Lemma global_extends_extend_parallel :
  forall ge GE,
    global_extends ge GE ->
    forall id e,
      global_extends (extend ge id e) (extend GE id e).
Proof.
  intros. unfold global_extends in *.
  intros. unfold extend in *.
  destruct (ident_eq id0 id); eauto.
Qed.

Lemma global_extends_declare_parallel :
  forall l ge GE,
    global_extends ge GE ->
    global_extends (declare l ge) (declare l GE).
Proof.
  induction l; intros.
  simpl. assumption.
  simpl. destruct a. destruct d.
  eapply IHl. eapply global_extends_extend_parallel; eauto.
  destruct (lookup_prim id).
  eapply IHl. eapply global_extends_extend_parallel; eauto.
  eapply IHl; eauto.
Qed.

Lemma global_extends_bind_decl_groups :
  forall decls ge GE,
    global_extends ge GE ->
    global_extends (bind_decl_groups decls ge) (bind_decl_groups decls GE).
Proof.
  induction decls; intros.
  simpl. assumption.
  simpl. eapply IHdecls; eauto.
  destruct a; simpl;
    try destruct d; try destruct d; simpl;
      [ idtac | idtac | destruct (lookup_prim id) eqn:? ];
      eauto;
      try solve [eapply global_extends_extend_parallel; eauto].
  eapply global_extends_declare_parallel; eauto.
Qed.

Lemma eager_eval_type_swap_ge :
  forall ge GE TE te t,
    eager_eval_type ge TE te t ->
    eager_eval_type GE TE te t.
Proof.
  induction 1; intros; econstructor; eauto.
Admitted. (* needs special induction scheme for eager_eval_type *)

Lemma strict_eval_val_swap_ge :
  forall ge GE v sv,
    strict_eval_val ge v sv ->
    strict_eval_val GE v sv.
Proof.
  induction 1; intros; try solve [econstructor; eauto]; subst.
  * econstructor; eauto.
    admit. (* strict_eval_val induction scheme *)
  * econstructor; eauto.
    admit. (* strict_eval_val induction scheme *)
  * econstructor; eauto.
    admit. (* needs ge swap for eval_expr *)
  * econstructor; eauto.
    admit. (* strict_eval_val induction scheme *)
Admitted. 

Lemma global_extends_eager_eval :
    forall expr v ge TE SE,
      eager_eval_expr ge TE SE expr v ->
      forall GE,
        global_extends ge GE ->
        eager_eval_expr GE TE SE expr v.
Proof.
  remember (fun ge TE SE llm llidv =>
             eager_par_match ge TE SE llm llidv ->
             forall GE,
               global_extends ge GE ->
               eager_par_match GE TE SE llm llidv) as Ppm.
  remember (fun ge TE SE lm llidv =>
             eager_index_match ge TE SE lm llidv ->
             forall GE,
               global_extends ge GE ->
               eager_index_match GE TE SE lm llidv) as Pm.

  induction 1 using eager_eval_expr_ind_useful with
      (Pm := Pm) (Ppm := Ppm); intros;
    try solve [econstructor; eauto];
    subst Pm Ppm.

  * econstructor.
    induction H0; intros; econstructor; inversion H; eauto.
  * econstructor.
    induction H0; intros; econstructor; inversion H; eauto.
  * econstructor.
    eapply IHeager_eval_expr; eauto.
    eapply global_extends_bind_decl_groups; eauto.
  * econstructor; eauto.
    eapply eager_eval_type_swap_ge; eauto.
  * econstructor; eauto.
    eapply strict_eval_val_swap_ge; eauto.
  * econstructor; eauto.
    clear H1.
    induction H0; intros. econstructor.
    econstructor; eauto.
    inversion H. eauto.
  * econstructor; eauto.
    clear H1.
    induction H0; intros.
    econstructor.
    econstructor; eauto.
    (* Need different Ppm? *)
    admit. 
  * econstructor; eauto.
    clear H2.
    induction H; intros; econstructor; eauto.
    eapply eager_eval_type_swap_ge; eauto.
    clear H2. clear H.
    induction H0; intros.
    econstructor.
    inversion H1. subst.
    econstructor; eauto.
  * intros.
    econstructor. inversion H0. eauto.
    congruence.
  * intros. inversion H2. subst. econstructor.
    
    (* need IHeager_eval_expr strengthened *)
Admitted.

(* lowercase is concrete, uppercase is abstract *)
(* wf_env lets this proof be used over a variety of environments that meet the proper constraints *)
Definition wf_env (ge GE : genv) (TE : tenv) (SE : senv)  : Prop :=
  name_irrel ge /\ name_irrel GE /\ name_irrel TE /\ name_irrel SE /\ (*finite GE /\*)
  (forall id,
      ge id <> None -> (TE id = None /\ SE id = None /\ ge id = GE id)).


Lemma name_irrel_diff_results :
  forall {A} E id id',
    @name_irrel A E ->
    E id <> E id' ->
    exists p,
      ident_eq id id' = right p.
Proof.
  intros.
  unfold name_irrel in H.
  specialize (H id id').
  destruct (ident_eq id id') eqn:?.
  congruence.
  exists n. eauto.
Qed.


Lemma name_irrel_extend :
  forall {A} E id (x : A),
    name_irrel E ->
    name_irrel (extend E id x).
Proof.
  intros. unfold name_irrel in *.
  intros.
  specialize (H id0 id').
  destruct (ident_eq id0 id') eqn:?; auto.
  unfold extend.
  destruct (ident_eq id0 id);
    destruct (ident_eq id' id); auto.
  rewrite e in e0. congruence.
  rewrite e in n. congruence.
Qed.

Lemma name_irrel_erase :
  forall {A} (E : ident -> option A) id,
    name_irrel E ->
    name_irrel (fun x => if ident_eq x id then None else E x).
Proof.
  intros.
  unfold name_irrel in *.
  intros.
  specialize (H id0 id').
  destruct (ident_eq id0 id'); auto.
  rewrite H.
  destruct (ident_eq id0 id);
    destruct (ident_eq id' id);
    auto; congruence.
Qed.

