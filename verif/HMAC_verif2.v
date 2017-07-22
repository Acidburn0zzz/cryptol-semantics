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

Require Import EvalTac.

Import HaskellListNotations.
Open Scope string.

Require Import HMAC.

Require Import HMAC_spec.

Require Import HMAC_lib.

Require Import Kinit_eval2.

(* Now we can use ext_val to characterize the inputs to HMAC *)
(* As well, we can simply write HMAC over ext_val *)

(* Model of hmac, given model of hash *)
Definition hmac_model (hf : strictval -> strictval) (key msg : strictval) : option strictval := None. (* TODO *)

Lemma eager_eval_bind_senvs :
  forall l GE TE exp SE id,
    (forall sv, exists v, eager_eval_expr GE TE (extend SE id sv) exp v) ->
    exists vs,
      Forall2 (fun se => eager_eval_expr GE TE se exp)
              (bind_senvs SE (map (fun sv => [(id,sv)]) (map to_sval l))) vs.
Proof.
  induction l; intros.
  eexists. econstructor; eauto.
  edestruct IHl; eauto.
  specialize (H (to_sval a)).
  destruct H.
  eexists.
  unfold map. fold (map to_sval).
  econstructor; eauto.
Qed.

(* lemma for when the length of the key is the same as the length of the block *)
Lemma Hmac_eval_keylen_is_blocklength :
  forall (key : ext_val) keylen,
    has_type key (bytestream keylen) -> 
    forall GE TE SE, 
      wf_env ge GE TE SE ->
      forall h hf,
        good_hash h GE TE SE hf ->
        forall msg msglen unused,
          has_type msg (bytestream msglen) ->
          exists v,
            eager_eval_expr GE TE SE (apply (tapply (EVar hmac) ((typenum (Z.of_nat msglen)) :: (typenum (Z.of_nat keylen)) :: (typenum unused) :: (typenum (Z.of_nat keylen)) :: nil)) (h :: h :: h :: (EValue (to_val key)) :: (EValue (to_val msg)) :: nil)) v /\ hmac_model hf (to_sval key) (to_sval msg) = Some v.
Proof.
  intros.
  init_globals ge.
  abstract_globals ge.
  edestruct good_hash_eval; eauto.
  do 3 destruct H3.

  inversion H. subst.
  inversion H2. subst.

  edestruct eager_eval_bind_senvs.
  Focus 2.
  eexists; split.

  e. e. e. e. e. e. e. e. e.
  ag.

  e. e. e. e. e.
  eassumption.
  e. eassumption.
  e. eassumption.
  e. e.

  eapply strict_eval_val_to_val.

  e. e.
  eapply strict_eval_val_to_val.

  e. e. e. e. e. e. e. e.
  g. 
  admit. (* not local *)
  e.
  e. e. e.
  eapply eager_eval_global_var.
  admit. (* not local *)
  reflexivity.
  e. e. e. eapply eager_eval_global_var.
  admit.
  reflexivity.


  eapply kinit_eval.
  admit. exact H.
  admit. repeat e. repeat e.
  repeat e. e.
  
  simpl.
  rewrite list_of_strictval_of_strictlist. 
  reflexivity.

  eapply H4. (* generated from lemma that probably needs strengthening *)
  
  e. g.
  e. e. e. e. g.
  simpl. unfold extend. simpl. eapply wf_env_not_local; eauto.
  reflexivity.
  e. e. e. e. e. e. e. e. e. e. e. g.
  simpl. unfold extend. simpl. eapply wf_env_not_local; eauto.
  reflexivity.
  e. e. e. e. g.
  e. e. e. g.
  eapply kinit_eval.
  admit. exact H.
  admit. repeat e.
  repeat e. repeat e. e.

  simpl.
  rewrite list_of_strictval_of_strictlist. 
  reflexivity.

  admit. (* come back here *)

  e. e. e. repeat e.
  repeat e.
  
  unfold to_sval. fold to_sval.
  rewrite append_strict_list. 
  reflexivity.

  (* This is about the hash function *)
  admit. (* come back here *)

  e. repeat e.
  e. e. e.

  admit. (* split things, unused is not unused *)

  e. repeat e. repeat e.
  
  admit. (* append *)

  (* evaluate the hash function *)
  admit.

  (* our result matches the model *)
  admit.

  e. e. e. e. g. unfold extend. simpl.
  admit. e. e. e. e. e. e. g.
  unfold extend. simpl. admit.
  e. e. e. repeat e.
  e.
  reflexivity.
  e. e. e. e. e. e. e. e.
  admit.
  
Admitted.