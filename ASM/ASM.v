Require Import Lib.
Require Import BinaryProps.
Require Import List.
Require Import Program.
Require Import LazyList.
Require Import Semantics.
Require Import Memory.
Require Export DoOption.


(* a toy assembly language *)

Module Instruction : INSTRUCTION.

  Inductive register': Type :=
  | REG1
  | REG2
  | REG3
  | REG4
  | REG5
  | REG6
  | REG7
  | REG8.

  Definition register := register'.

  Definition register_eq_dec  (r1 r2: register): {r1 = r2}+{r1 <> r2}.
  Proof.
    decide equality.
  Qed.


  Inductive instruction' : Type :=
  | Instr_noop: instruction'
  | Instr_and: register -> word -> register -> instruction'
  | Instr_read: register -> register -> instruction'
  | Instr_write: register -> register -> instruction'
  | Instr_direct_jump: word -> instruction'
  | Instr_direct_cond_jump: register -> word -> instruction'
  | Instr_indirect_jump: register -> instruction'
  | Instr_os_call: word -> instruction'.

  Definition instruction := instruction'.

  Open Scope nat_scope.

  Definition reg_from_byte (b:byte) : option register :=
    match fst b with
      | HB0 =>
        match snd b with
          | HB1 => Some (REG1)
          | HB2 => Some (REG2)
          | HB3 => Some (REG3)
          | HB4 => Some (REG4)
          | HB5 => Some (REG5)
          | HB6 => Some (REG6)
          | HB7 => Some (REG7)
          | HB8 => Some (REG8)
          | _ => None
        end
      | _ => None
    end.



  Function parse_instruction (ll: lazy_list byte) : option (instruction * nat):=
    match ll with
      | 〈〉 => None
        (* No op *)
      | (HB0, HB0) ::: _ => Some (Instr_noop, 1)
      | (HB0, HB1) ::: reg_code1 ::: b1 ::: b2 ::: b3 ::: b4 ::: reg_code2 ::: _ =>
        do reg1 <- reg_from_byte reg_code1;
        do reg2 <- reg_from_byte reg_code2;
          (* we assume a little endian processor *)
        Some (Instr_and reg1 (W b4 b3 b2 b1) reg2, 7)
      | (HB0, HB2) ::: reg_code1 ::: reg_code2 ::: _ =>
        do reg1 <- reg_from_byte reg_code1;
        do reg2 <- reg_from_byte reg_code2;
        Some (Instr_read reg1 reg2, 3)
      | (HB0, HB3) ::: reg_code1 ::: reg_code2 ::: _ =>
        do reg1 <- reg_from_byte reg_code1;
        do reg2 <- reg_from_byte reg_code2;
        Some (Instr_write reg1 reg2, 3)
      | (HB0, HB4) ::: b1 ::: b2 ::: b3 ::: b4 ::: _ =>
        Some (Instr_direct_jump (W b4 b3 b2 b1), 5)
      | (HB0, HB5) ::: reg_code1 ::: b1 ::: b2 ::: b3 ::: b4 ::: _ =>
        do reg1 <- reg_from_byte reg_code1;
          (* we assume a little endian processor *)
        Some (Instr_direct_cond_jump reg1 (W b4 b3 b2 b1), 6)
      | (HB0, HB6) ::: reg_code1 :::  _ =>
        do reg1 <- reg_from_byte reg_code1;
          (* we assume a little endian processor *)
        Some (Instr_indirect_jump reg1, 2)
      | (HB0, HB7) ::: _ =>
        Some (Instr_os_call (W byte0 byte0 byte0 byte0), 1)
      | _ => None
    end.

  Definition instr_max_size: nat := 7.

  Ltac fun_ind_parse_instr_with call :=
    functional induction call;
      [ fst_Case_tac "fun_ind_parse_instr 1"
      |  fst_Case_tac "fun_ind_parse_instr 2"
      |  fst_Case_tac "fun_ind_parse_instr 3"
      |  fst_Case_tac "fun_ind_parse_instr 4"
      |  fst_Case_tac "fun_ind_parse_instr 5"
      |  fst_Case_tac "fun_ind_parse_instr 6"
      |  fst_Case_tac "fun_ind_parse_instr 7"
      |  fst_Case_tac "fun_ind_parse_instr 8"
      |  fst_Case_tac "fun_ind_parse_instr 9"
      |  fst_Case_tac "fun_ind_parse_instr 10"
      |  fst_Case_tac "fun_ind_parse_instr 11"
      |  fst_Case_tac "fun_ind_parse_instr 12"
      |  fst_Case_tac "fun_ind_parse_instr 13"
      |  fst_Case_tac "fun_ind_parse_instr 14"
      |  fst_Case_tac "fun_ind_parse_instr 15"
      |  fst_Case_tac "fun_ind_parse_instr 16"
      |  fst_Case_tac "fun_ind_parse_instr 17"
      |  fst_Case_tac "fun_ind_parse_instr 18"].


  Ltac fun_ind_parse_instr :=
    match goal with
      | H: context[ parse_instruction ?ll] |- _ =>
        fun_ind_parse_instr_with (parse_instruction ll)
      | |- context[ parse_instruction ?ll] =>
        fun_ind_parse_instr_with (parse_instruction ll)
    end.


  Lemma parse_instruction_do_read:
    forall ll instr n, parse_instruction ll = Some (instr, n) ->
    (ll_length ll >= n)%nat.
  Proof.
    intros.
    fun_ind_parse_instr; simpl; clean; try omega.
  Qed.

  Lemma inv_ll_cons: forall X (x1:X) l1 x2 l2,
    tag_to_inv (ll_cons x1 l1 = ll_cons x2 l2).
  Proof. constructor. auto. Qed.
  Hint Rewrite inv_ll_cons: opt_inv.


  Lemma parse_instruction_only_read:
    forall ll instr n, parse_instruction ll = Some (instr, n) ->
    forall ll',
      ll_safe_take n ll' = ll_safe_take n ll ->
      parse_instruction ll' = Some (instr, n).
  Proof.
    intros.
    fun_ind_parse_instr; simpl in *; clean; simpl in *;    
    repeat match goal with
      | H : context [match ?l with
                       | ll_nil => _
                       | ll_cons _ _ => _
                     end] |- _ =>
      destruct l as [|? []]; clean
    end; simpl in *; try (rewrite e0); try (rewrite e1); auto.
  Qed.
    

  Lemma size_instr_not_0: forall ll instr n,
    parse_instruction ll = Some (instr, n) -> n <> O.
  Proof.
    intros.
    fun_ind_parse_instr; simpl in *; clean; simpl in *; auto.
  Qed.

  Lemma size_instr_inf_max_size: forall ll instr n,
    parse_instruction ll = Some (instr, n) -> (n <= instr_max_size)%nat.
  Proof.
    unfold instr_max_size. intros.
    fun_ind_parse_instr; simpl in *; clean; simpl in *; auto;omega.
  Qed.


  Definition classify_instruction instr :=
    match instr with
      | Instr_noop => OK_instr
      | Instr_and reg1 w reg2 =>
        if register_eq_dec reg1 reg2 then
          Mask_instr reg1 w
        else
          OK_instr
      | Instr_read _ _ => OK_instr
      | Instr_write _ _ => OK_instr
      | Instr_direct_jump w => Direct_jump w
      | Instr_direct_cond_jump reg w => Direct_jump w
      | Instr_indirect_jump reg => Indirect_jump reg
      | Instr_os_call w => Invalid_instruction
    end.


  Definition read_word (mem:memory) addr : option word :=
    do b1 <- mem addr;
    do b2 <- mem (addr + 1)%N;
    do b3 <- mem (addr + 2)%N;
    do b4 <- mem (addr + 3)%N;
    Some (W b4 b3 b2 b1).

  Definition write_byte (mem:memory) addr byte : memory:=
    fun n =>
      if N_eq_dec n addr then Some byte else mem n.

  Definition write_word (mem:memory) addr w :=
    match w with
      | W b4 b3 b2 b1 =>
        write_byte (write_byte (write_byte (write_byte mem addr b1) (addr + 1) b2)
          (addr + 2) b3) (addr + 3) b4
    end%N.

  Lemma read_write_word: forall mem addr w,
    read_word (write_word mem addr w) addr = Some w.
  Proof.
    intros.
    unfold read_word, write_word, write_byte.
    destruct w as [b4 b3 b2 b1].
    repeat
      match goal with
        | |- context[N_eq_dec ?v1 ?v2] =>
          destruct (N_eq_dec v1 v2); try (elimtype False; omega')
      end.
    reflexivity.
  Qed.

  Definition update_reg (regs: register -> word) reg w :=
    fun r => if register_eq_dec r reg then w else regs r.

Open Scope N_scope.

  Inductive instruction_semantics' (code_size:N): instruction ->
    state register -> instruction_target_state register -> Prop :=
  | IS_noop: forall mem regs pc,
    instruction_semantics' code_size Instr_noop
    {| state_mem := mem;  state_regs := regs;  state_pc := pc |}
    (Good_state {| state_mem := mem;
                   state_regs := regs;
                   state_pc := pc + 1|})
  | IS_and: forall mem regs pc reg1 reg2 w,
    instruction_semantics' code_size (Instr_and reg1 w reg2)
    {| state_mem := mem;  state_regs := regs;  state_pc := pc |}
    (Good_state {| state_mem := mem;
                   state_regs := update_reg regs reg2 (word_and w (regs reg1));
                   state_pc := pc + 7|})
  | IS_read: forall mem regs pc reg1 reg2 addr w,
    addr = N_of_word (regs reg1) ->
    Some w = read_word mem addr ->
    instruction_semantics' code_size (Instr_read reg1 reg2)
    {| state_mem := mem;  state_regs := regs;  state_pc := pc |}
    (Good_state {| state_mem := mem;
                   state_regs := update_reg regs reg2 w;
                   state_pc := pc + 3|})
  | IS_write: forall mem regs pc reg1 reg2 addr,
    addr = N_of_word (regs reg2) ->
    (* we cannot write in the header !!! *)
    (header_size + code_size <= addr)%N ->
    instruction_semantics' code_size (Instr_write reg1 reg2)
    {| state_mem := mem;  state_regs := regs;  state_pc := pc |}
    (Good_state {| state_mem := write_word mem addr (regs reg1);
                   state_regs := regs;
                   state_pc := pc + 3|})
  | IS_direct_jump: forall mem regs pc w,
    instruction_semantics' code_size (Instr_direct_jump w)
    {| state_mem := mem;  state_regs := regs;  state_pc := pc |}
    (Good_state {| state_mem := mem;
                   state_regs := regs;
                   state_pc := N_of_word w |})
  | IS_direct_cond_jump_yes: forall mem regs pc reg w,
    regs reg <> word_of_N 0 ->
    instruction_semantics' code_size (Instr_direct_cond_jump reg w)
    {| state_mem := mem;  state_regs := regs;  state_pc := pc |}
    (Good_state {| state_mem := mem;
                   state_regs := regs;
                   state_pc := N_of_word w |})
  | IS_direct_cond_jump_no: forall mem regs pc reg w,
    regs reg = word_of_N 0 ->
    instruction_semantics' code_size (Instr_direct_cond_jump reg w)
    {| state_mem := mem;  state_regs := regs;  state_pc := pc |}
    (Good_state {| state_mem := mem;
                   state_regs := regs;
                   state_pc := pc + 6 |})
  | IS_indirect_jump: forall mem regs pc reg,
    instruction_semantics' code_size (Instr_indirect_jump reg)
    {| state_mem := mem;  state_regs := regs;  state_pc := pc |}
    (Good_state {| state_mem := mem;
                   state_regs := regs;
                   state_pc := N_of_word (regs reg)|})
  | IS_os_call: forall st w,
    instruction_semantics' code_size (Instr_os_call w)
    st Bad_state.

  Definition instruction_semantics := instruction_semantics'.


  (* the first parameter is to indicate that the n first bytes of the memory
     cannot be written *)


  (* an instruction cannot write in the lower code segment *)
  Lemma sem_no_overwrite: forall code_size instr st1 st2,
    instruction_semantics code_size instr st1 (Good_state st2) ->
    forall n', n' < header_size + code_size -> st1.(state_mem) n' = st2.(state_mem) n'.
  Proof.
    intros.
    inv H; simpl; auto.
    remember (N_of_word (regs reg2)) as n. clear Heqn.
    unfold write_word, write_byte.
    destruct (regs reg1) as [b4 b3 b2 b1].
    repeat
      match goal with
        | |- context[N_eq_dec ?v1 ?v2] =>
          destruct (N_eq_dec v1 v2); try (elimtype False; omega')
      end.
    reflexivity.
  Qed.
    

  (* the "good" instructions can get stuck but neverr lead to a "bad state" *)

  Lemma sem_not_invalid_not_bad: forall instr,
    classify_instruction instr <> Invalid_instruction ->
    forall code_size st,
      ~ instruction_semantics code_size instr st Bad_state.
  Proof.
    intros. intro.
    inv H0. simpl in H. congruence.
  Qed.

  Lemma sem_OK_instr_pc: forall bm instr size,
    parse_instruction bm = Some (instr, size) ->
    classify_instruction instr = OK_instr ->
    forall code_size st1 st2,
    instruction_semantics code_size instr st1 (Good_state st2) ->
    st2.(state_pc) = st1.(state_pc) + (N_of_nat size).
  Proof.
    intros.
    fun_ind_parse_instr; clean; inv H1; try reflexivity; inv H0.
  Qed.

  Lemma sem_Mask_instr_pc: forall bm instr size,
    parse_instruction bm = Some (instr, size) ->
    forall reg w,
    classify_instruction instr = Mask_instr reg w->
    forall code_size st1 st2,
    instruction_semantics code_size instr st1 (Good_state st2) ->
    st2.(state_pc) = st1.(state_pc) + (N_of_nat size).
  Proof.
    intros.
    fun_ind_parse_instr; clean; try inv H0.
    inv H1; reflexivity.
  Qed.



  Lemma sem_Mask_instr_reg: forall bm instr size,
    parse_instruction bm = Some (instr, size) ->
    forall reg w,
    classify_instruction instr = Mask_instr reg w->
    forall code_size st1 st2,
    instruction_semantics code_size instr st1 (Good_state st2) ->
    st2.(state_regs) reg = word_and w (st1.(state_regs) reg).
  Proof.
    intros.
    fun_ind_parse_instr; clean; try solve [inv H0].
    simpl in H0.
    destruct (register_eq_dec a a0); subst.
    inv H0.
    inv H1. simpl. unfold update_reg.
    destruct register_eq_dec; congruence.
    inv H0.
  Qed.

  Lemma sem_Direct_jump_pc: forall bm instr size,
    parse_instruction bm = Some (instr, size) ->
    forall w,
    classify_instruction instr = Direct_jump w ->
    forall code_size st1 st2,
    instruction_semantics code_size instr st1 (Good_state st2) ->
    st2.(state_pc) = st1.(state_pc) + (N_of_nat size) \/
    st2.(state_pc) = N_of_word w.
  Proof.
    intros.
    fun_ind_parse_instr; clean; try solve [inv H0].
    Case "fun_ind_parse_instr 3".
    simpl in H0. destruct register_eq_dec in H0; inv H0.
    Case "fun_ind_parse_instr 12".
    inv H0. inv H1. auto.
    Case "fun_ind_parse_instr 13".
    inv H0. inv H1; auto.
  Qed.
    

  Lemma sem_Indirect_jump_pc: forall bm instr size,
    parse_instruction bm = Some (instr, size) ->
    forall reg,
    classify_instruction instr = Indirect_jump reg ->
    forall code_size st1 st2,
    instruction_semantics code_size instr st1 (Good_state st2) ->
    st2.(state_pc) = st1.(state_pc) + (N_of_nat size) \/
    st2.(state_pc) = N_of_word (st1.(state_regs) reg).
  Proof.
    intros.
    fun_ind_parse_instr; clean; try solve [inv H0].
    Case "fun_ind_parse_instr 3".
    simpl in H0. destruct register_eq_dec in H0; inv H0.
    Case "fun_ind_parse_instr 15".
    inv H0. inv H1; auto.
  Qed.

End Instruction.

