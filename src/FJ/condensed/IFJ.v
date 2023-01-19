Require Import String.
Require Import FJ.Lists.
Require Import FJ.Base.

Notation "'[' X ']'" := (list X) (at level 40).

(* We could use Inductive for ClassNames and Vars, 
 * but would make the other definitions cumbersome to deal with 
 * the special names Object and this.
 * ClassNames are our types.
 *)


Definition ClassName := id.
(* Given a ClassTable, 
    the programmer needs to specify which ID is the Object *)
Parameter Object: ClassName.

Definition InterfaceName := id.

Inductive ty : Set :=
  | class : ClassName -> ty 
  | interface : InterfaceName -> ty.

(* Vars must appear only inside methods body *)
Definition Var := id.
(* Similar for this variable *)
Parameter this: Var.

Inductive Argument :=
  | Arg : id -> Argument.

(* FormalArg and FieldDecl is a ClassName (i.e. a type) and an id *)
Inductive FormalArg :=
  | FArg : ty -> id -> FormalArg.
Inductive FieldDecl :=
  | FDecl : ty -> id -> FieldDecl.

(* The class Referable essentialy means I can use the ref function
 * to retrieve the id of a value.
 * And it also gives me a nice function ´find´ for free.
 * See Util.Referable
*)
Instance FargRef : Referable FormalArg :={
  ref farg := 
    match farg with 
   | FArg _ id => id end
}.
Instance FieldRef : Referable FieldDecl :={
  ref fdecl := 
    match fdecl with 
   | FDecl _ id => id end
}.

(* fargType and fieldType are a means to retrieve the Type of the declarations *)
Definition fargType (f: FormalArg):ty := 
  match f with FArg t _ => t end.
Definition fieldType (f: FieldDecl): ty := 
  match f with FDecl t _ => t end.

(* Our expressions are Variables,
 * field acesses,
 * method invocations,
 * cast
 * and new
*)
Inductive Exp : Type :=
  | ExpVar : Var -> Exp
  | ExpFieldAccess : Exp -> id -> Exp
  | ExpMethodInvoc : Exp -> id -> [Exp] -> Exp
  | ExpCast : ty -> Exp -> Exp
  | ExpNew : ClassName -> [Exp] -> Exp.

Inductive Assignment :=
  | Assgnmt : Exp -> Exp -> Assignment.

(* Constructor declaration \texttt{C(\={C}~\={f})\{super(\={f}); this.\={f}=\={f};\}} and a constructor refinement 
 * \texttt{refines~C(\={E}~\={h}, \={C}~\={f}) \{original(\={f}); this.\={f}=\={f};\}} introduces a constructor with 
 * for the class \texttt{C} with fields \texttt{\=f} of type \texttt{\=C}. The constructor declaration body is simply 
 * a list of assignment of the arguments with its correspondent field preceded by calling its superclass constructor with the correspondent arguments.
 * The constructor refinement only differs from constructor declaration that instead of calling the superclass constructor
 * it will call its predecessor constructor (denoted by \texttt{original}).
 *)
Inductive Constructor :=
  | KDecl : id -> [FormalArg] -> [Argument] -> [Assignment] -> Constructor.

Inductive MethodTy :=
  | mty : id -> ty -> forall (fargs: [FormalArg]), NoDup (this :: refs fargs)  -> MethodTy.
Instance MethodTyRef : Referable MethodTy :={
  ref mdecl := 
    match mdecl with 
   | (mty id _ _ _)  => id end
}.

(* Method declaration \texttt{C~m~(\={C}~\={x})\ \{return~e;\}} 
 * introduces a method \texttt{m} of return type \texttt{C} with arguments \texttt{\={C}~\={x}} and body \texttt{e}.
 * Method declarations should only appear inside a class declaration.
 *)
Inductive MethodDecl :=
  | MDecl :  MethodTy -> Exp -> MethodDecl.


Instance MDeclRef : Referable MethodDecl :={
  ref mdecl := 
    match mdecl with 
   | MDecl (mty id _ _ _) _ => id end
}.

(* A class declaration \texttt{class\ C~extends~D\ \{\={C} \={f}; K \={M}\}} 
 * introduces a class \texttt{C} with superclass \texttt{D}. This class has fields \texttt{\=f}
 * of type \texttt{C}, a constructor \texttt{K} and methdos \texttt{\=M}. The fields of class \texttt{C}
 * is \texttt{\=f} added to the fields of its superclass \texttt{D}, all of them must have distinct names.
 * Methods, in the other, hand may override another superclass method with the same name.
 * Method override in \ac{FJ} is basically method rewrite. 
 * Methods are uniquely identified by its name, i.e. overload is not supported.
 *)
(* Featherweight Java Level (without interface) *)
(* Overridable EXT1 : Set = []. 
Overridable deafult_ext1 : EXT1. *)

(* This intermediate version I feel safe about the pattern matching *)

(* The automatic version,  *)

Inductive TypeDecl:=
  | CDecl: ClassName -> ClassName -> [InterfaceName] ->
    forall (fDecls:[FieldDecl]), NoDup (refs fDecls) -> Constructor -> 
    forall (mDecls:[MethodDecl]), NoDup (refs mDecls) -> TypeDecl
  | IDecl: InterfaceName -> [MethodTy] -> TypeDecl.

Instance TypeDeclRef : Referable TypeDecl :={
  ref cdecl := 
    match cdecl with 
   | CDecl id _ _ _ _ _ _ _ => id 
   | IDecl id _ => id end
}.



Inductive Program :=
  | CProgram : forall (cDecls: [TypeDecl]), NoDup (refs cDecls) -> Exp -> Program.

(* We assume a fixed Class/InterfaceTable *)
Parameter CT: [TypeDecl].

Require Import Relations Decidable.


Reserved Notation "C '<:' D " (at level 40).
(* Subtyping relation is (freely) generated by
    ClassTables
  in the following section we need to specify the restriction 
    on the ClassTables *)
Inductive Subtype : ty -> ty -> Prop :=
  | S_Refl: forall C, C <: C
  | S_Trans: forall C D E, 
    C <: D -> 
    D <: E -> 
    C <: E
  | S_CDecl: forall C D ints fs noDupfs K mds noDupMds,
    find C CT = Some (CDecl C D ints fs noDupfs K mds noDupMds ) ->
    (class C) <: (class D)
  | S_IDecl: forall C i l,
    find C CT = Some (IDecl i l) ->
    (class C) <: (interface i)
where "C '<:' D" := (Subtype C D).
Hint Constructors Subtype.

Tactic Notation "subtype_cases" tactic(first) ident(c) :=
  first;
  [ Case_aux c "S_Refl"  | Case_aux c "S_Trans" 
  | Case_aux c "S_CDecl" | Case_aux c "S_IDecl"].

Reserved Notation "'mtype(' m ',' D ')' '=' c '~>' c0" (at level 40, c at next level).

Inductive m_type (m: id) : ty -> [ty] -> ty -> Prop:=
  | mty_class : forall C D Fs ints K Ms noDupfs noDupMds fargs noDupfargs e Bs B,
              find C CT = Some (CDecl C D ints Fs noDupfs K Ms noDupMds)->
              find m Ms = Some (MDecl (mty m B fargs noDupfargs) e) ->
              map fargType fargs = Bs ->
              mtype(m, class C) = Bs ~> B
  | mty_no_override: forall C D Fs ints K Ms noDupfs noDupMds Bs B,
              find C CT = Some (CDecl C D ints Fs noDupfs K Ms noDupMds) ->
              find m Ms = None ->
              mtype(m, class D) = Bs ~> B ->
              mtype(m, class C) = Bs ~> B
  | mty_interface : forall C Ms fargs noDup1 Bs B,
             find C CT = Some (IDecl C Ms)->
             find m Ms = Some (mty m B fargs noDup1) ->
             map fargType fargs = Bs ->
             mtype(m, interface C) = Bs ~> B
  where "'mtype(' m ',' D ')' '=' cs '~>' c0"
        := (m_type m D cs c0).

Tactic Notation "mtype_cases" tactic(first) ident(c) :=
  first;
  [ Case_aux c "mty_class" | Case_aux c "mty_no_override"
  | Case_aux c "mty_interface" ].

Inductive m_body (m: id) (C: ClassName) (xs: [id]) (e: Exp) : Prop:=
  | mbdy_ok : forall C0 D ints Fs K Ms noDupfs noDupMds fargs noDupfargs,
              find C CT = Some (CDecl C D ints Fs noDupfs K Ms noDupMds)->
              find m Ms = Some (MDecl (mty m C0 fargs noDupfargs) e) ->
              refs fargs = xs ->
              m_body m C xs e
  | mbdy_no_override: forall D ints Fs K Ms noDupfs noDupMds,
              find C CT = Some (CDecl C D ints Fs noDupfs K Ms noDupMds)->
              find m Ms = None ->
              m_body m D xs e ->
              m_body m C xs e.
Notation "'mbody(' m ',' D ')' '=' xs 'o' e" := (m_body m D xs e) (at level 40).

Inductive fields : ClassName -> [FieldDecl] -> Prop :=
 | F_Obj : fields Object nil
 | F_Decl : forall C D ints fs  noDupfs K mds noDupMds fs', 
     find C CT = Some (CDecl C D ints fs noDupfs K mds noDupMds) ->
     fields D fs' ->
     NoDup (refs (fs' ++ fs)) ->
     fields C (fs'++fs).
Tactic Notation "fields_cases" tactic(first) ident(c) :=
  first;
  [ Case_aux c "F_Obj" | Case_aux c "F_Decl"].

Hint Constructors m_type m_body fields.
Tactic Notation "mbdy_cases" tactic(first) ident(c) :=
  first;
  [ Case_aux c "mbdy_ok" | Case_aux c "mbdy_no_override"].

Fixpoint subst (e: Exp) (ds: [Exp]) (xs: [Var]): Exp := 
  match e with
  | ExpVar var => match find_where var xs with
                  | Some i => match nth_error ds i with
                                   | None => e | Some di => di end
                  | None => e end
  | ExpFieldAccess exp i => ExpFieldAccess (subst exp ds xs) i
  | ExpMethodInvoc exp i exps => 
      ExpMethodInvoc (subst exp ds xs) i (map (fun x => subst x ds xs) exps)
  | ExpCast cname exp => ExpCast cname (subst exp ds xs)
  | ExpNew cname exps => ExpNew cname (map (fun x => subst x ds xs) exps)
  end.
Notation " [; ds '\' xs ;] e " := (subst e ds xs) (at level 30).


Inductive Warning (s: string) : Prop :=
  | w_str : Warning s.
Notation stupid_warning := (Warning "stupid warning").

(* We can make a stupid cast at anytime, but that rule must be flagged. *)
Axiom STUPID_STEP : stupid_warning.

Reserved Notation "Gamma '|--' x ':' C" (at level 60, x at next level).
Inductive ExpTyping (Gamma: env ty) : Exp -> ty -> Prop :=
  | T_Var : forall x C, get Gamma x = Some C -> 
                Gamma |-- ExpVar x : C
  | T_Field: forall e0 C0 fs i Fi Ci fi,
                Gamma |-- e0 : (class C0) ->
                fields C0 fs ->
                nth_error fs i = Some Fi ->
                Ci = fieldType Fi ->
                fi = ref Fi ->
                Gamma |-- ExpFieldAccess e0 fi : Ci
  | T_Invk : forall e0 C Cs C0 Ds m es,
                Gamma |-- e0 : C0 ->
                mtype(m, C0) = Ds ~> C ->
                Forall2 (ExpTyping Gamma) es Cs ->
                Forall2 Subtype Cs Ds ->
                Gamma |-- ExpMethodInvoc e0 m es : C
  | T_New : forall C Ds Cs fs es,
                fields C fs ->
                Ds = map fieldType fs ->
                Forall2 (ExpTyping Gamma) es Cs ->
                Forall2 Subtype Cs Ds ->
                Gamma |-- ExpNew C es : (class C)
  | T_UCast : forall e0 D C,
                Gamma |-- e0 : D ->
                D <: C ->
                Gamma |-- ExpCast C e0 : C
  | T_DCast : forall e0 C D,
                Gamma |-- e0 : D ->
                C <: D ->
                C <> D ->
                Gamma |-- ExpCast C e0 : C
  | T_SCast : forall e0 D C,
                Gamma |-- e0 : D ->
                ~ D <: C ->
                ~ C <: D ->
                stupid_warning ->
                Gamma |-- ExpCast C e0 : C
  where " Gamma '|--' e ':' C " := (ExpTyping Gamma e C).

Tactic Notation "typing_cases" tactic(first) ident(c) :=
  first;
  [ Case_aux c "T_Var" | Case_aux c "T_Field" 
  | Case_aux c "T_Invk" | Case_aux c "T_New"
  | Case_aux c "T_UCast" | Case_aux c "T_DCast" 
  | Case_aux c "T_SCast"].

Reserved Notation "e '~>!' e1" (at level 59).
Inductive Computation_step : Exp -> Exp -> Prop :=
  | R_Field : forall C Fs es fi ei i,
            fields C Fs ->
            nth_error Fs i = Some fi ->
            nth_error es i = Some ei-> 
            ExpFieldAccess (ExpNew C es) (ref fi) ~>! ei
  | R_Invk : forall C m xs ds es e0,
            mbody(m, C) = xs o e0 ->
            NoDup (this :: xs) ->
            List.length ds = List.length xs ->
            ExpMethodInvoc (ExpNew C es) m ds ~>! [; ExpNew C es :: ds \ this :: xs;] e0
  | R_Cast : forall C D es,
            (* This is so weird *)
            (class C) <: D ->
            ExpCast D (ExpNew C es) ~>! ExpNew C es
  where "e '~>!' e1" := (Computation_step e e1).
Tactic Notation "computation_step_cases" tactic(first) ident(c) :=
  first;
  [ Case_aux c "R_Field" | Case_aux c "R_Invk" 
  | Case_aux c "R_Cast" ].

Reserved Notation "e '~>' e1" (at level 60).
Inductive Computation : Exp -> Exp -> Prop :=
  | R_Step : forall e e1, e ~>! e1 -> e ~> e1
  | RC_Field : forall e0 e0' f,
            e0 ~> e0' ->
            ExpFieldAccess e0 f ~> ExpFieldAccess e0' f
  | RC_Invk_Recv : forall e0 e0' m es,
            e0 ~> e0' ->
            ExpMethodInvoc e0 m es ~> ExpMethodInvoc e0' m es
  | RC_Invk_Arg : forall e0 ei' m es es' ei i,
            ei ~> ei' ->
            nth_error es i = Some ei ->
            nth_error es' i = Some ei' ->
            (forall j, j <> i -> nth_error es j = nth_error es' j) ->
            length es = length es' ->
            ExpMethodInvoc e0 m es ~> ExpMethodInvoc e0 m es'
  | RC_New_Arg : forall C ei' es es' ei i,
            ei ~> ei' ->
            nth_error es i = Some ei ->
            nth_error es' i = Some ei' ->
            (forall j, j <> i -> nth_error es j = nth_error es' j) ->
            length es = length es' ->
            ExpNew C es ~> ExpNew C es'
  | RC_Cast : forall C e0 e0',
            e0 ~> e0' ->
            ExpCast C e0 ~> ExpCast C e0'
  where "e '~>' e1" := (Computation e e1).

Tactic Notation "computation_cases" tactic(first) ident(c) :=
  first;
  [ Case_aux c "R_Step" | Case_aux c "RC_Field"
  | Case_aux c "RC_Invk_Recv" | Case_aux c "RC_Invk_Arg" 
  | Case_aux c "RC_New_Arg" | Case_aux c "RC_Cast"].

Inductive Value : Exp -> Prop :=
  v_new: forall C es, Value (ExpNew C es).


Reserved Notation "e '~>*' e1" (at level 59).
Inductive ComputationStar : Exp -> Exp -> Prop := 
  | Comp_Refl : forall e,
    e ~>* e
  | Comp_Trans: forall e1 e2 e3,
    e1 ~>* e2 ->
    e2 ~>* e3 ->
    e1 ~>* e2
  where "e '~>*' e1" := (ComputationStar e e1).
Hint Constructors Computation ExpTyping Value ComputationStar.
Definition normal_form {X:Type} (R: relation X) (t: X) :=
  ~exists t', R t t'.


Definition assert_method_type (m: id) (D: ClassName) (Cs: [ty]) (C0: ty) :=
    (forall Ds D0, mtype(m, class D) = Ds ~> D0 -> (Ds = Cs /\ C0 = D0)).

Definition implement_interface (it : InterfaceName) (D: ClassName) :=
  forall mtys rety Cs,
  find it CT = Some (IDecl it mtys) ->
    forall mname fargs nodfargs,
      In (mty mname rety fargs nodfargs) mtys ->
      map fargType fargs = Cs ->
      assert_method_type mname D Cs rety.

Definition implement_interfaces (its : [InterfaceName]) (D: ClassName) :=
  forall it,
    In it its ->
    implement_interface it D.

Inductive MType_OK : ClassName -> MethodDecl -> Prop :=
  | T_Method : forall C D C0 E0 xs Cs e0 its Fs noDupfs  K Ms noDupMds fargs noDupFargs m,
            nil extds (this :: xs) : (class C :: Cs) |-- e0 : E0 ->
            E0 <: C0 ->
            find C CT = Some (CDecl C D its Fs noDupfs K Ms noDupMds) ->
            assert_method_type m D Cs C0 -> (* we only allow invariant *)
            map fargType fargs = Cs ->
            refs fargs = xs ->
            find m Ms = Some (MDecl (mty m C0 fargs noDupFargs) e0) ->
            MType_OK C (MDecl (mty m C0 fargs noDupFargs) e0).

Inductive CType_OK: TypeDecl -> Prop :=
  | T_Class : forall C D its Fs noDupfs K Ms noDupMds Cfargs Dfargs fdecl,
            K = KDecl C (Cfargs ++ Dfargs) (map Arg (refs Cfargs)) (zipWith Assgnmt (map (ExpFieldAccess (ExpVar this)) (refs Fs)) (map ExpVar (refs Fs))) ->
            fields D fdecl ->
            NoDup (refs (fdecl ++ Fs)) ->
            Forall (MType_OK C) (Ms) ->
            find C CT = Some (CDecl C D its Fs noDupfs K Ms noDupMds) ->
            CType_OK (CDecl C D its Fs noDupfs K Ms noDupMds).
(* I think all interfaces will be well-typed *)

(* Hypothesis for ClassTable sanity *)
Module CTSanity.

(* The freely generated relation must have Object as all the possible top,
  however, must be well-defined classes
  *)

Hypothesis obj_notin_dom: find Object CT = None.
Hint Rewrite obj_notin_dom.

(* This is to make sure ClassTable doesn't provide
    a cicular dependency *)
Hypothesis antisym_subtype:
  antisymmetric _ Subtype.


Hypothesis superClass_in_dom: forall C D ints Fs noDupfs K Ms noDupMds,
  find C CT = Some (CDecl C D ints Fs noDupfs K Ms noDupMds) ->
  D <> Object ->
  exists D0 ints0 Fs0 noDupfs0 K0 Ms0 noDupMds0, 
    find D CT = Some (CDecl D D0 ints0 Fs0 noDupfs0 K0 Ms0 noDupMds0).

Hypothesis ClassesOK: forall C D ints Fs noDupfs K Ms noDupMds, 
  find C CT = Some (CDecl C D ints Fs noDupfs K Ms noDupMds) ->
  CType_OK (CDecl C D ints Fs noDupfs K Ms noDupMds).
Hint Resolve ClassesOK.

Lemma subtype_obj_obj: forall C,
  (class Object) <: (class C) ->
  Object = C.
Proof.
  assert (forall Obj CC,
  Obj <: CC ->
  Obj = class Object ->
  CC = class Object); eauto.
  intros Obj CC H.
  induction H; crush.
  intros. forwards*: (H _ _ H0). injection H1; eauto.
Qed.

Lemma sub_not_obj: forall C,
  Object <> C ->
  ~ (class Object) <: (class C).
Proof.
  Hint Resolve subtype_obj_obj.
assert (forall Obj CC,
  Obj <: CC ->
  forall C,
  Object <> C ->
  Obj = class Object ->
  CC = class C ->
  False) as H.
  intros Obj CC h. induction h; intros; subst;crush.
  forwards*: subtype_obj_obj.

  intros_all. forwards*:(H _ _ H1 _ H0).
Qed.

(* The heart of problem is to prove this *)
Parameter dec_subtype: forall C D,
  decidable (Subtype C D).

(* All the nontrivial postulation are located in CTSanity
    and we will focus on dealing them in decidable_subtype.v

  these postulations, when I say them nontrivial, as we don't see 
  a general way of proving a given [ClassDecl] satisfy these 5 postulation

  and thus decidable_subtype.v
     is trying to give a general way to prove these stuff
     *)

End CTSanity.

(* Print Forall2.  *)

Definition ExpTyping_ind' := 
  fun (Gamma : env ty) (P : Exp -> ty -> Prop)
  (f : forall (x : id) (C : _), get Gamma x = Some C -> P (ExpVar x) C)
  (f0 : forall (e0 : Exp) (C0 : _) (fs : [FieldDecl]) (i : nat) (Fi : FieldDecl)
          (Ci : _) (fi : id),
        Gamma |-- e0 : class C0 ->
        P e0 (class C0) ->
        fields C0 fs ->
        nth_error fs i = Some Fi -> Ci = fieldType Fi -> fi = ref Fi -> 
        P (ExpFieldAccess e0 fi) Ci)
  (f1 : forall (e0 : Exp) (C : _) (Cs : _) (C0 : _) (Ds : _) 
          (m : id) (es : [Exp]),
        Gamma |-- e0 : C0 ->
        P e0 (C0) ->
        mtype( m, C0)= Ds ~> C ->
        Forall2 (ExpTyping Gamma) es Cs ->
        Forall2 Subtype Cs Ds -> 
        Forall2 P es Cs ->
        P (ExpMethodInvoc e0 m es) C)
  (f2 : forall (C : id) (Ds Cs : _) (fs : [FieldDecl]) (es : [Exp]),
        fields C fs ->
        Ds = map fieldType fs ->
        Forall2 (ExpTyping Gamma) es Cs ->
        Forall2 Subtype Cs Ds -> 
        Forall2 P es Cs ->
        P (ExpNew C es) (class C))
  (f3 : forall (e0 : Exp) (D C : _), Gamma |-- e0 : D -> P e0 D -> D <: C -> P (ExpCast C e0) C)
  (f4 : forall (e0 : Exp) (C : _) (D : _),
        Gamma |-- e0 : D -> P e0 D -> C <: D -> C <> D -> P (ExpCast C e0) C)
  (f5 : forall (e0 : Exp) (D C : _),
        Gamma |-- e0 : D -> P e0 D -> ~ D <: C -> ~ C <: D -> stupid_warning -> P (ExpCast C e0) C) =>
fix F (e : Exp) (c : _) (e0 : Gamma |-- e : c) {struct e0} : P e c :=
  match e0 in (_ |-- e1 : c0) return (P e1 c0) with
  | T_Var _ x C e1 => f x C e1
  | T_Field _ e1 C0 fs i Fi Ci fi e2 f6 e3 e4 e5 => f0 e1 C0 fs i Fi Ci fi e2 (F e1 (class C0) e2) f6 e3 e4 e5
  | T_Invk _ e1 C Cs C0 Ds m es e2 m0 f6 f7 => f1 e1 C Cs C0 Ds m es e2 (F e1 C0 e2) m0 f6 f7 
          ((fix list_Forall_ind (es' : [Exp]) (Cs' : _) 
            (map : Forall2 (ExpTyping Gamma) es' Cs'): 
               Forall2 P es' Cs' :=
            match map with
            | Forall2_nil _ => Forall2_nil P
            | (@Forall2_cons _ _ _ ex cx ees ccs H1 H2) => Forall2_cons ex cx (F ex cx H1) (list_Forall_ind ees ccs H2)
          end) es Cs f6)
  | T_New _ C Ds Cs fs es f6 e1 f7 f8 => f2 C Ds Cs fs es f6 e1 f7 f8
          ((fix list_Forall_ind (es' : [Exp]) (Cs' : _) 
            (map : Forall2 (ExpTyping Gamma) es' Cs'): 
               Forall2 P es' Cs' :=
            match map with
            | Forall2_nil _ => Forall2_nil P
            | (@Forall2_cons _ _ _ ex cx ees ccs H1 H2) => Forall2_cons ex cx (F ex cx H1) (list_Forall_ind ees ccs H2)
          end) es Cs f7)
  | T_UCast _ e1 D C e2 s => f3 e1 D C e2 (F e1 D e2) s
  | T_DCast _ e1 C D e2 s n => f4 e1 C D e2 (F e1 D e2) s n
  | T_SCast _ e1 D C e2 s s0 w => f5 e1 D C e2 (F e1 D e2) s s0 w
  end.

Include CTSanity.


(* Auxiliary Lemmas *)
(* mtype / MType_OK lemmas *)
Lemma unify_returnType' : forall Ds D C' C D0 ints Fs noDupfs K Ms noDupMds C0 m fargs noDupfargs ret,
  mtype( m, C')= Ds ~> D ->
  C' = class C ->
  find C CT = Some (CDecl C D0 ints Fs noDupfs K Ms noDupMds) ->
  find m Ms = Some (MDecl (mty m C0 fargs noDupfargs) ret) ->
  D = C0.
Proof.
  induction 1; crush.
Qed.


Lemma unify_fargsType : forall Ds D C' C D0 ints Fs noDupfs K Ms noDupMds C0 m fargs noDupfargs ret,
  mtype( m, C')= Ds ~> D ->
  C' = class C ->
  find C CT = Some (CDecl C D0 ints Fs noDupfs K Ms noDupMds) ->
  find m Ms = Some (MDecl (mty m C0 fargs noDupfargs) ret) ->
  Ds = map fargType fargs.
Proof.
  induction 1; crush.
Qed.

Lemma methodDecl_OK :forall C D0 ints Fs noDupfs K Ms noDupMds C0 m fargs noDupfargs ret,
  find m Ms = Some (MDecl (mty m C0 fargs noDupfargs) ret) ->
  find C CT = Some (CDecl C D0 ints Fs noDupfs K Ms noDupMds) ->
  MType_OK C (MDecl (mty m C0 fargs noDupfargs) ret).
Proof.
  intros. apply ClassesOK in H0; inversion H0.
  match goal with
  [ H: Forall _ _ |- _ ] =>  eapply Forall_find in H; eauto
  end.
Qed.
Hint Resolve methodDecl_OK.

Lemma exists_mbody': forall C' D Cs m,
  mtype(m, C') = Cs ~> D ->
  forall C,
  C' = class C ->

  exists xs e, mbody(m, C) = xs o e /\ NoDup (this :: xs) /\ List.length Cs = List.length xs.
Proof. 
  induction 1; intros; eauto;
  try match goal with
  | [ H : class _ = class _ |- _ ] =>  injection H; intros; subst; eauto
  end; try discriminate.
  - exists (refs fargs) e; repeat (split; eauto); crush. 
  - forwards*: (IHm_type  _ eq_refl). crush; eexists; eexists; eauto.
Qed.

Lemma exists_mbody: forall C' C D Cs m,
  mtype(m, C') = Cs ~> D ->
  C' = class C ->
  exists xs e, mbody(m, C) = xs o e /\ NoDup (this :: xs) /\ List.length Cs = List.length xs.
eauto using exists_mbody'.
Qed.

(* find C CT Lemmas *)

Lemma mtype_obj_False: forall m Cs C,
  mtype(m, class Object) = Cs ~> C ->
  False.
Proof.
  inversion 1; crush.
Qed.
Hint Resolve mtype_obj_False.

Lemma super_obj_or_defined: forall C D ints Fs noDupfs K Ms noDupMds,
    find C CT = Some (CDecl C D ints Fs noDupfs K Ms noDupMds) ->
    D = Object \/ exists D0 ints0 Fs0 noDupfs0 K0 Ms0 noDupMds0, 
                    find D CT = Some (CDecl D D0 ints0 Fs0 noDupfs0 K0 Ms0 noDupMds0).
Proof.
  intros. destruct beq_id_dec with D Object; subst.
  left; auto.
  right. eapply superClass_in_dom; eauto.
Qed.


(* fields Lemmas *)
Lemma fields_obj_nil: forall f,
  fields Object f -> f = nil.
Proof.
  remember Object.
  induction 1; crush.
Qed.

Lemma fields_NoDup : forall C fs,
  fields C fs ->
  NoDup (refs fs).
Proof.
  inversion 1; crush.
Qed.

Lemma fields_det: forall C f1 f2,
  fields C f1 ->
  fields C f2 ->
  f1 = f2.
Proof.
  Hint Resolve fields_obj_nil.
  intros; gen f1.
  fields_cases (induction H0) Case; intros.
  Case "F_Obj".
    crush.
  Case "F_Decl".
    match goal with 
    [ H: fields _ _ |- _ ] => destruct H; [crush |]
    end.
    match goal with
    [ H: fields _ ?fs |- _] => specialize IHfields with fs; crush
    end.
Qed.

Ltac class_OK C:=
  match goal with
    | [ H: find C ?CT = Some (CDecl _ _ _ _ _ _ _ ) |- _ ] => 
      apply ClassesOK in H; inversion H; subst; sort; clear H
  end.


Ltac mtype_OK m :=
  match goal with
    | [ H: find ?C _ = Some (CDecl _ _ _ _ _ ?Ms _ ), H1: find m ?Ms = Some (MDecl _ _ _ _ _) |- _ ] => 
      eapply methodDecl_OK in H1; eauto; inversion H1; subst; sort; clear H1
  end.

Ltac unify_returnType :=  match goal with
  | [H: mtype( ?m, ?C)= ?Ds ~> ?D,
     H1: find ?C _ = Some (CDecl ?C _ _ _ _ ?Ms _),
     H2: find ?m ?Ms = Some (MDecl ?D ?m _ _ _) |- _ ] => fail 1 (*needed for no infinite loop *)
  | [H: mtype( ?m, ?C)= ?Ds ~> ?D,
     H1: find ?C _ = Some (CDecl ?C _ _ _ _ ?Ms _),
     H2: find ?m ?Ms = Some (MDecl ?C0 ?m _ _ _) |- _ ] => lets ?H: unify_returnType' H H1 H2; subst
  end.

Ltac unify_fargsType :=  match goal with
  | [H: mtype( ?m, ?C)= map fargType ?fargs ~> ?D,
     H1: find ?C _ = Some (CDecl ?C _ _ _ _ ?Ms _),
     H2: find ?m ?Ms = Some (MDecl _ ?m ?fargs _ _) |- _ ] => fail 1
  | [H: mtype( ?m, ?C)= ?Ds ~> ?D,
     H1: find ?C _ = Some (CDecl ?C _ _ _ _ ?Ms _),
     H2: find ?m ?Ms = Some (MDecl _ ?m ?fargs _ _) |- _ ] => lets ?H: unify_fargsType H H1 H2; subst
  end.

Ltac insterU H :=
  repeat match type of H with
           | forall x : ?T, _ =>
             let x := fresh "x" in
               evar (x : T);
               let x' := eval unfold x in x in
                 clear x; specialize (H x')
         end.

Ltac superclass_defined_or_obj C :=
  match goal with
  | [H1: find C _ = _ |- _ ] => edestruct super_obj_or_defined; [eexact H1 |  | ]; subst
  end.

Ltac find_dec_with T Ref L i :=
  destruct (@find_dec T) with Ref L i.

Ltac find_dec_tac L i:=
  match type of L with
  | list ?T => let H := fresh "H" in destruct (find_dec L i) as [H|H]
  end.

Ltac decompose_ex H :=
  repeat match type of H with
           | ex (fun x => _) =>
             let x := fresh x in
             destruct H as [x H]; sort
         end.

Ltac decompose_exs :=
  repeat match goal with
  | [H: exists x, _ |- _ ] => decompose_ex H
  end.

Ltac inv_decl :=
  let C := fresh "C" in
  let D := fresh "D" in
  let K := fresh "K" in
  let m := fresh "m" in
  let f := fresh "f" in
  let fargs := fresh "fargs" in
  let noDupFargs := fresh "noDupFargs" in
  let fDecls := fresh "fDecls" in
  let noDupfDecls := fresh "noDupfDecls" in
  let mDecls := fresh "mDecls" in
  let noDupmDecls := fresh "noDupmDecls" in
  repeat match goal with
  | [ MD : MethodDecl |- _ ] => destruct MD as [C m fargs noDupFargs e]
  | [ FD : FieldDecl |- _ ] => destruct FD as [C f]
  | [ CD : ClassDecl |- _ ] => destruct CD as [C D fDecls noDupfDecls mDecls noDupmDecls]
  end.

Ltac unify_find_ref :=
let H := fresh "H" in
  match goal with
  | [H1: find ?x ?xs = Some ?u |- _] =>
    match eval cbn in (ref u) with
    | x  => fail 1
    | _ => assert (ref u = x) as H by (eapply find_ref_inv; eauto); simpl in H; subst
    end
  end.

Ltac Forall_find_tac :=
  let H := fresh "H" in
  match goal with
  | [ H1: Forall ?P ?l, H2: find ?x ?l = _ |- _ ] => lets H: H1; eapply Forall_find in H; [|eexact H2]; clear H1
  end.

Ltac mtypes_ok :=
  match goal with
  | [H: MType_OK _ _ |- _ ] => destruct H; subst; sort; clear H
  end.

Ltac elim_eqs :=
  match goal with
  | [H: ?x = _, H1: ?x = _ |- _ ] => rewrite H in H1; inversion H1; clear H1; subst
  end.

Ltac unify_override :=
  match goal with
  | [H: assert_method_type ?m ?D ?Cs ?C0, H1: mtype(?m, ?D) = ?Ds ~> ?D0 |- _ ] => destruct H with Ds D0; [exact H1 | subst; clear H]
  end.

Ltac unify_fields :=
  match goal with
  | [ H1: fields ?C ?f1, H2: fields ?C ?f2 |- _ ] => destruct (fields_det _ _ _ H1 H2); subst; clear H2
  end.

Ltac unifall :=
  repeat (decompose_exs || inv_decl || unify_find_ref || elim_eqs
  || unify_override || unify_fields || unify_returnType || unify_fargsType
  || mtypes_ok  || Forall_find_tac).

Ltac ecrush := unifall; eauto; crush; eauto.

Lemma methods_same_signature: forall C D Fs noDupfs K Ms noDupMds Ds D0 m,
    find C CT = Some (CDecl C D Fs noDupfs K Ms noDupMds) ->
    mtype(m, D) = Ds ~> D0 ->
    mtype(m, C) = Ds ~> D0.
Proof.
  intros; class_OK C.
  find_dec_tac Ms m; ecrush.
Qed.
(* Subtype Lemmas *)

Lemma obj_not_subtype: forall C,
  C <> Object -> ~ Object <: C.
Proof.
  intros; intro. 
  remember Object. induction H0; [auto | | crush].
  subst. destruct beq_id_dec with D Object; subst; auto.
Qed.

Lemma subtype_fields: forall C D fs ,
  C <: D ->
  fields D fs ->
  exists fs', fields C (fs ++ fs').
Proof.
  Hint Rewrite app_nil_r app_assoc.
  intros. gen H0. gen fs.
  subtype_cases (induction H) Case; intros.
  Case "S_Refl".
    exists (@nil FieldDecl); crush.
  Case "S_Trans".
    repeat match goal with
    | [H: forall fs, fields ?C fs -> _, H1: fields ?C ?fs|- _ ] => destruct (H fs H1); clear H
    end; ecrush.
  Case "S_Decl".
    class_OK C; ecrush.
Qed.

Lemma subtype_order:
  order _ Subtype.
Proof.
  refine {| ord_refl:= (S_Refl); ord_trans:= (S_Trans); ord_antisym:=antisym_subtype|}.
Qed.

Lemma super_class_subtype: forall C D D0 fs noDupfs K mds noDupMds,
 C <: D -> C <> D ->
 find C CT = Some (CDecl C D0 fs noDupfs K mds noDupMds) ->
 D0 <: D.
Proof.
  intros C D D0 fs noDupfs K mds noDupMds H.
  gen D0 fs noDupfs K mds noDupMds.
  induction H; [crush | intros | crush].
  destruct beq_id_dec with C D; ecrush.
Qed.

Lemma subtype_not_sub': forall C D E,
  E <: C ->
  E <: D ->
  C <: D \/ D <: C.
Proof.
  Hint Resolve super_class_subtype.
  intros C D E H. gen D.
  induction H; auto; intros. 
  - edestruct IHSubtype1; eauto.
  - destruct beq_id_dec with C D0; ecrush.
Qed.

Lemma subtype_not_sub: forall C D E,
    E <: D ->
  ~ C <: D ->
  ~ D <: C ->
  ~ E <: C.
Proof.
  intros_all.
  match goal with
  | [H: ?E <: ?D, H1: ?E <: ?C |- _ ] => edestruct subtype_not_sub' with (D:=D); eauto
  end.
Qed.

(* subst Lemmas *)
Lemma var_subst_in: forall ds xs x i di,
  nth_error xs i = Some x ->
  nth_error ds i = Some di ->
  NoDup xs ->
  [; ds \ xs ;] (ExpVar x) = di.
Proof.
  Hint Rewrite nth_error_nil.
  intros. gen ds xs i.
  induction ds, xs; crush.
  apply findwhere_ntherror in H; crush.
Qed.

(* Paper Lemmas *)

Lemma A11: forall m D C Cs C0,
          C <: D ->
          mtype(m,D) = Cs ~> C0 ->
          mtype(m,C) = Cs ~> C0.
Proof.
  Hint Resolve methods_same_signature.
  induction 1; eauto.
Qed.


Lemma weakening: forall Gamma e C,
  nil |-- e : C ->
  Gamma |-- e : C.
Proof.
  induction 1 using ExpTyping_ind'; eauto; crush.
Qed.



Lemma A14: forall D m C0 xs Ds e,
  mtype(m,C0) = Ds ~> D ->
  mbody(m,C0) = xs o e ->
  exists D0 C,  C0 <: D0 /\ C <: D /\
  nil extds (this :: xs) : (D0 :: Ds) |-- e : C.
Proof.
  intros.
  mbdy_cases (induction H0) Case.
  mtype_OK m. exists C E0. unifall; eauto.
  Case "mbdy_no_override".
    inversion H; ecrush.
    exists x x0; ecrush.
Qed.


Theorem term_subst_preserv_typing : forall Gamma xs (Bs: list ClassName) D ds As e,
  nil extds xs : Bs |-- e : D ->
  NoDup xs ->
  Forall2 (ExpTyping Gamma) ds As ->
  Forall2 Subtype As Bs ->
  length ds = length xs ->
  exists C, (C <:D /\ Gamma |-- [; ds \ xs ;] e : C).
Proof with eauto.
  intros.
  typing_cases (induction H using ExpTyping_ind') Case; sort.
  Case "T_Var".
    destruct (In_dec (beq_id_dec) x xs) as [xIn|xNIn]; unifall; eauto.
    SCase "In x xs". rename C into Bi.
      assert (In x xs); eauto.
      apply nth_error_In' in xIn as [i]. symmetry in H3.
      edestruct (@nth_error_same_len id Exp) as [di]...
      assert (nth_error Bs i = Some Bi).
      eapply get_noDup_extds; eauto; constructor; eauto. 
      destruct (Forall2_nth_error _ _ (ExpTyping Gamma) ds As i di) as [Ai]...
      exists Ai.
      split.
      eapply Forall2_forall... erewrite var_subst_in; eauto.
      eapply Forall2_forall...
    SCase "~In x xs". 
      split with C. split. eauto.
      erewrite notin_extds in H... inversion H. 
  Case "T_Field".
    simpl. destruct IHExpTyping as [C']. destruct H8. 
    exists Ci. 
    split...
    eapply subtype_fields in H8... destruct H8 as [fs'].
    eapply T_Field. eassumption.  eapply H8. eapply nth_error_app_app... auto. auto.
  Case "T_Invk". rename C0 into D0.
    destruct IHExpTyping as [C0]. destruct H8.
    apply A11 with (m:=m) (Cs:=Ds) (C0:=C) in H8...
    exists C. split; auto. simpl. 
    apply Forall2_exi in H7. destruct H7 as [Cs']. sort. destruct H7.
    apply Forall2_trans with (zs:= Ds) in H7; auto.
    eapply T_Invk; eauto.
    apply Forall2_map; auto.
    intros x y z ?H ?H1; apply S_Trans with y; auto. 
  Case "T_New".
    apply Forall2_exi in H7. destruct H7 as [Cs']. destruct H7; sort.
    exists C; split; auto. simpl. 
    apply Forall2_trans with (zs:= Ds) in H7; auto.
    eapply T_New...
    apply Forall2_map; auto.
    intros x y z ?H ?H1; apply S_Trans with y; auto.
  Case "T_UCast".
    exists C. split; auto. simpl.
    destruct IHExpTyping as [E]. destruct H5.
    eapply T_UCast...
  Case "T_DCast".
    exists C; split; auto. simpl.
    destruct IHExpTyping as [E]. destruct H6.
    destruct dec_subtype with E C.
    eapply T_UCast in H7...
    destruct beq_id_dec with E C. rewrite e in H8; false; apply H8; auto.
    destruct dec_subtype with C E.
    eapply T_DCast in H7...
    eapply T_SCast in H7...
    apply STUPID_STEP.
  Case "T_SCast".
    exists C; split; auto. simpl.
    destruct IHExpTyping as [E]. destruct H7.
    eapply T_SCast...
    eapply subtype_not_sub...
Qed. 

Lemma exists_subtyping : forall Gamma es es' Cs Ds i ei ei' C D C0,
  nth_error es i = Some ei ->
  nth_error es' i = Some ei' ->
  nth_error Cs i = Some C ->
  nth_error Ds i = Some D ->
  Forall2 Subtype Cs Ds ->
  C0 <: C ->
  Gamma |-- ei' : C0 ->
  Forall2 (ExpTyping Gamma) es Cs ->
  (forall j, j <> i -> nth_error es j = nth_error es' j) ->
  exists Cs', Forall2 Subtype Cs' Ds /\
             Forall2 (ExpTyping Gamma) es' Cs'.
Proof.
  intros. 
  exists (List.app (firstn i Cs)  (List.app (cons C0 nil) (skipn (S i) Cs))).
  gen i ei' H H0 H1 H2 H3 H5. gen es' Ds. induction H6 as [| ?e ?C ?es ?Cs].
  intros. crush.
  intros. 
  destruct es' as [| es']; [rewrite nth_error_nil in H1; inversion H1|].
  destruct Ds as [| Ds]; [rewrite nth_error_nil in H3; inversion H3|].
  destruct i. simpl in *. crush. inversion H5; constructor; auto. subst. apply S_Trans with C; auto.
  constructor; auto.
  assert (forall i, nth_error es i = nth_error es'0 i). intro.
  lets ?H: H7 (S i). 
 simpl in H0. apply H0; intuition.
  apply nth_error_same with (xs' := es'0) in H0. rewrite <- H0; auto. 
  edestruct IHForall2 with (es':= es'0); eauto; intros.
  lets ?H: H7 (S j); crush. inversion H5; auto.
  clear IHForall2.
  split. crush. constructor; auto. inversion H5; auto.
  crush. constructor; auto.
  lets ?H: H7 0. simpl in H11. assert (e = es'); crush.
Qed.


Inductive Eval_Ctx : Type :=
  | C_hole : Eval_Ctx
  | C_field_invk : Eval_Ctx -> id -> Eval_Ctx
  | C_minvk_recv: Eval_Ctx -> id -> [Exp] -> Eval_Ctx
  | C_minv_arg: Exp -> id -> [Exp] -> Eval_Ctx -> [Exp] -> Eval_Ctx
  | C_cast: ClassName -> Eval_Ctx -> Eval_Ctx
  | C_new: ClassName -> [Exp] -> Eval_Ctx -> [Exp] -> Eval_Ctx.

(* It's isCtx which actually enforces standard call-by-value 
   But since our implementation is a non deterministic reduciton, it wont be needed
   I'll leave it here anyways
*)
Inductive isCtx : Eval_Ctx -> Prop :=
  | is_hole : isCtx C_hole
  | is_field_invk : forall ev id, isCtx (C_field_invk ev id)
  | is_minvk_recv: forall ev id es, isCtx (C_minvk_recv ev id es)
  | is_minv_arg: forall v id vs es ctx, Value v -> Forall Value vs -> isCtx (C_minv_arg v id vs ctx es)
  | is_cast: forall c ctx, isCtx (C_cast c ctx)
  | is_new: forall c vs ctx es, Forall Value vs -> isCtx (C_new c vs ctx es).
Hint Constructors Eval_Ctx isCtx.

Fixpoint plug (ctx: Eval_Ctx) (e: Exp) : Exp :=
  match ctx with
  | C_hole => e
  | C_field_invk ctx' id => ExpFieldAccess (plug ctx' e) id
  | C_minvk_recv ctx' id es => ExpMethodInvoc (plug ctx' e) id es
  | C_minv_arg v id vs ctx' es => 
        ExpMethodInvoc v id (vs ++ cons (plug ctx' e) nil ++ es)
  | C_cast C ctx' => ExpCast C (plug ctx' e)
  | C_new C vs ctx' es => 
        ExpNew C (vs ++ cons (plug ctx' e) nil ++ es)
  end.
Notation "E [; t ;]" := (plug E t) (no associativity, at level 60).
Notation "[ . ]" := (C_hole) (no associativity, at level 59).


Lemma ctx_next_subterm': forall e e',
  e ~>! e' ->
  exists E r r',  e = E [; r ;] /\ 
                  e' = E [; r' ;] /\ 
                  r ~>! r'.
Proof.
  intros.
  exists C_hole e e'. split; eauto.
Qed.

Lemma ctx_next_correct: forall e e',
  e ~> e' ->
  exists E r r',  e = E [; r ;] /\ 
                  e' = E [; r' ;] /\ 
                  r ~>! r'.
Proof.
  Hint Resolve ctx_next_subterm'.
  intros.
  computation_cases (induction H) Case; eauto; destruct IHComputation as (E & r & r' & ?H & ?H & ?H).
  Case "RC_Field".
    exists (C_field_invk E f). 
    repeat eexists; crush.
  Case "RC_Invk_Recv".
    exists (C_minvk_recv E m es).
    repeat eexists; crush.
  Case "RC_Invk_Arg".
    Hint Resolve nth_error_split.
    exists (C_minv_arg e0 m (firstn i es) E (skipn (S i) es)).
    remember (skipn (S i) es).
    repeat eexists; eauto; simpl; subst;  apply f_equal.
    lets ?H: (nth_error_split es) H0; auto.
    erewrite firstn_same with (ys := es'); eauto. 
    erewrite skipn_same with (ys := es'); eauto.
  Case "RC_New_Arg".
    exists (C_new C(firstn i es) E (skipn (S i) es)).
    remember (skipn (S i) es).
    repeat eexists; eauto; simpl; subst;  apply f_equal.
    lets ?H: (nth_error_split es) H0; auto.
    erewrite firstn_same with (ys := es'); eauto. 
    erewrite skipn_same with (ys := es'); eauto.
  Case "RC_Cast".
    exists (C_cast C E). repeat eexists; crush.
Qed.


(* This is Theorem 2.4.1 at the paper *)
Theorem preservation_step : forall Gamma e e' C,
  Gamma |-- e : C ->
  e ~>! e' ->
  exists C', C' <: C /\ Gamma |-- e' : C'.
Proof with eauto.
  intros. gen C.
  computation_step_cases (induction H0) Case; intros.
  Case "R_Field".
    subst. destruct fi; simpl in *.
    inversion H2; subst. simpl in *. destruct Fi in *. simpl in *. subst. 
    rename C1 into D0. sort. assert (C = D0). inversion H5. reflexivity. subst.
    rewrite (fields_det D0 fs Fs) in H7 by auto.
    clear H6 fs. assert ((FDecl c0 i0) = (FDecl c i0)).
    eapply ref_noDup_nth_error; eauto.  eapply fields_NoDup; eauto. inversion H3.
    inversion H5. subst. sort.
    rewrite (fields_det D0 Fs fs) in H0 by auto.
    rewrite (fields_det D0 Fs fs) in H7 by auto.
    clear H H3 H12 H7 Fs. 
    assert (nth_error es i <> None). intro. crush.
    assert (List.length es = List.length Cs) by (apply (Forall2_len _ _ _ _ _ H11)).
    apply -> (nth_error_Some) in H. rewrite H3 in H.
    assert (exists Ci, nth_error Cs i = Some Ci). 
    apply nth_error_Some'. assumption.
    destruct H4 as [Ci].
     destruct (Forall2_nth_error _ _ (Subtype) Cs (map fieldType fs) i Ci) as [fi']...
    exists Ci.
    split. sort. 
    apply map_nth_error with (B:=ClassName) (f:=fieldType) in H0; simpl in *.
    eapply Forall2_forall...
    apply (Forall2_forall _ _ (ExpTyping Gamma) es Cs i ei Ci); auto.
  Case "R_Invk".
    inversion H2. subst. inversion H6; subst; sort.
    eapply A14 in H7... 
    destruct H7 as [B]. destruct H3. destruct H3. destruct H4.
    eapply term_subst_preserv_typing with (ds := ExpNew C2 es :: ds) in H7...
    destruct H7 as [E]. destruct H7.
    exists E; split; eauto.
    apply eq_S; auto.
  Case "R_Cast". 
    assert (D = C0) by (inversion H0; crush); subst. 
    inversion_clear H0. repeat eexists; eauto. 
    assert (C = D) by (inversion H1; crush); subst.
    false. apply antisym_subtype in H2. auto.
    assert (C = D) by (inversion H1; crush); subst. contradiction.
Qed.

Theorem preservation : forall Gamma e e' C,
  Gamma |-- e : C ->
  e ~> e' ->
  exists C', C' <: C /\ Gamma |-- e' : C'.
Proof with eauto.
  intros. gen C.
  computation_cases (induction H0) Case; intros.
  Case "R_Step".
    eapply preservation_step; eauto.
  Case "RC_Field".
    inversion H; subst. eapply IHComputation in H3. 
    destruct H3 as (C' & ?H & ?H).
    lets ?H: subtype_fields H1 H4; eauto. destruct H3.
    apply nth_error_app_app with (l':=x) in H5. eauto.
  Case "RC_Invk_Recv".
    inversion H; subst. apply IHComputation in H4. 
    destruct H4 as (C' & ?H & ?H).
    eapply A11 in H1; eauto.
  Case "RC_Invk_Arg".
    inversion H4; subst.
    exists C; split; eauto.
    lets ?H: Forall2_nth_error H11 H. destruct H5 as [?C].
    lets ?H: Forall2_nth_error H12 H5. destruct H6 as [?D].
    lets: H11.
    eapply Forall2_forall with (n:=i) (x:=ei) in H11; eauto. 
    eapply IHComputation in H11. destruct H11 as (?C' & ?H & ?H).
    edestruct exists_subtyping with (es := es) (Cs := Cs) (es':= es') (Ds:= Ds) as (Cs' & ?H & ?H); eauto.
  Case "RC_New_Arg".
    inversion H4; subst.
    lets ?H: Forall2_nth_error H9 H. destruct H5 as [?C].
    lets ?H: Forall2_nth_error H11 H5. destruct H6 as [?D].
    exists C0; split; auto. 
    lets ?H: H9.
    eapply Forall2_forall with (n:=i) (x:=ei) in H8; eauto. 
    eapply IHComputation in H8. destruct H8 as (?C' & ?H & ?H).
    edestruct exists_subtyping with (es := es) (Cs := Cs) (es':= es') (Ds:= map fieldType fs) as (Cs' & ?H & ?H); eauto.
  Case "RC_Cast".
    assert (C0 = C) by (inversion H; crush); subst.
    inversion H; subst; eapply (IHComputation) in H3; destruct H3 as [C0']; destruct H1. eauto.
    rename D into C0. clear H5.
    destruct dec_subtype with C0' C.
    eapply T_UCast in H2; eauto.
    destruct dec_subtype with C C0'.
    eapply T_DCast in H2; eauto. crush.
    eapply T_SCast in H2; eauto. apply STUPID_STEP.
    rename D into C0. clear H6.
    exists C; split; eauto. eapply T_SCast; eauto. 
    eapply subtype_not_sub...
Qed.

Theorem progress: forall e C,
  nil |-- e : C ->
  normal_form Computation e ->
  Value e \/
  (exists E C D es, e = E [; ExpCast C (ExpNew D es);] /\ ~ D <: C).
Proof.
  intros.
  typing_cases (induction H using ExpTyping_ind') Case; intros.
  Case "T_Var". inversion H.
  Case "T_Field".
    Hint Rewrite fields_det.
    unfold normal_form in *. destruct IHExpTyping.
    intro. apply H0. destruct H5 as [e0']. exists (ExpFieldAccess e0' fi); eauto.
    SCase "Value".
      inversion H5; subst. inversion H; subst.
      assert (fs = fs0) by (eapply fields_det; eauto). subst. clear H1.
      false; apply H0. 
      assert (nth_error (map fieldType fs0) i = Some (fieldType Fi)) by (apply map_nth_error; eauto).
      lets ?H: Forall2_nth_error' Cs H10 H1. destruct H3 as [Ci].
      lets ?H: Forall2_nth_error' Cs H8 H3. destruct H4 as [ei].
      exists ei. constructor. econstructor; eauto.
    SCase "Stuck".
      destruct H5 as (E & C & D & es & H5 & H6).
      right. exists (C_field_invk E fi);  repeat eexists; subst; simpl ; eauto.
  Case "T_Invk".
    unfold normal_form in *. destruct IHExpTyping.
    intro. apply H0. destruct H5 as [e0']. exists (ExpMethodInvoc e0' m es); eauto.
    SCase "Value".
      inversion H5; subst. inversion H; subst. sort.
      false. apply H0. edestruct exists_mbody as (xs &e' & ?H & ?H & ?H); eauto.
      exists ([; ExpNew C0 es0 :: es \ this :: xs;] e'); constructor. constructor; eauto.
      apply Forall2_len in H2. apply Forall2_len in H3. rewrite <- H9. rewrite H2; auto.
    SCase "Stuck".
      edestruct exists_mbody as (xs &e' & ?H & ?H & ?H); eauto.
      destruct H5 as (?E & ?C & ?D & ?es & ?H & ?H). sort.
      right. exists (C_minvk_recv E m es); repeat eexists; subst; simpl; eauto.
  Case "T_New". eauto.
  Case "T_UCast".
    unfold normal_form in *. destruct IHExpTyping.
    intro. apply H0. destruct H2 as [e0']. eauto.
    SCase "Value".
      inversion H2; subst. inversion H; subst. sort.
      false. apply H0. exists (ExpNew D es); eauto. constructor; eauto. constructor. eauto.
    SCase "Stuck".
      destruct H2 as (?E & ?C & ?D & ?es & ?H & ?H). sort.
      right. exists (C_cast C E). repeat eexists; subst; simpl; eauto.
  Case "T_DCast".
    unfold normal_form in *. destruct IHExpTyping.
    intro. apply H0. destruct H3 as [e0']. eexists; eauto.
    SCase "Value".
      inversion H3; subst. inversion H; subst.
      right. exists (C_hole). simpl. repeat eexists; eauto. intro. apply antisym_subtype in H1. intuition.
    SCase "Stuck".
      destruct H3 as (?E & ?C & ?D & ?es & ?H & ?H). sort.
      right. exists (C_cast C E). repeat eexists; subst; simpl; eauto.
  Case "T_SCast".
    unfold normal_form in *. destruct IHExpTyping.
    intro. apply H0. destruct H4 as [e0']. eexists; eauto.
    SCase "Value".
      inversion H4; subst. inversion H; subst. sort.
      right. exists C_hole. simpl. eauto.
    SCase "Stuck".
      destruct H4 as (?E & ?C & ?D & ?es & ?H & ?H). sort.
      right. exists (C_cast C E); repeat eexists; subst; simpl; eauto.
Qed.
