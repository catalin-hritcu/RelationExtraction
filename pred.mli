(****************************************************************************)
(*  RelationExtraction - Extraction of inductive relations for Coq          *)
(*                                                                          *)
(*  This program is free software: you can redistribute it and/or modify    *)
(*  it under the terms of the GNU General Public License as published by    *)
(*  the Free Software Foundation, either version 3 of the License, or       *)
(*  (at your option) any later version.                                     *)
(*                                                                          *)
(*  This program is distributed in the hope that it will be useful,         *)
(*  but WITHOUT ANY WARRANTY; without even the implied warranty of          *)
(*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the           *)
(*  GNU General Public License for more details.                            *)
(*                                                                          *)
(*  You should have received a copy of the GNU General Public License       *)
(*  along with this program.  If not, see <http://www.gnu.org/licenses/>.   *)
(*                                                                          *)
(*  Copyright 2011 CNAM-ENSIIE                                              *)
(*                 Catherine Dubois <dubois@ensiie.fr>                      *)
(*                 David Delahaye <david.delahaye@cnam.fr>                  *)
(*                 Pierre-Nicolas Tollitte <tollitte@ensiie.fr>             *)
(****************************************************************************)

open Host_stuff

(* Extraction failure with some reason. *)
exception RelationExtractionError of string

(***************)
(* Identifiers *)
(***************)

(* Identifier for everything. *)
type ident
val string_of_ident : ident -> string
val ident_of_string : string -> ident


(*********)
(* Types *)
(*********)

(* Generic type of a term *)
type clear_type = 
  | CTTuple of clear_type list (* Types of tuple's elements. *)
  | CTSum of ident list (* List of constructors of a sum type. *)
  | CTNone (* No type information. *)
type 'htyp term_type = (clear_type * 'htyp host_term_type)
type ('t, 'htyp) typed = ('t * 'htyp term_type)


(************)
(* ML Terms *)
(************)

(* Mode *)
type mode_option = 
  | MInput
  | MOutput
  | MSkip (* used for host language stuff, must be ignored *)
type mode = mode_option list

type 'htyp untyped_ml_pat =
(* Standard constructions *)
  | MLPVar of ident
  | MLPTuple of 'htyp ml_pat list
  | MLPRecord of ident list * 'htyp ml_pat list
  | MLPConstr of ident * 'htyp ml_pat list
  | MLPConst of ident
  | MLPWild

(* Additionnal stuff *)
  (* Used for linearization. *)
  | MLPATrue | MLPAFalse
  (* Used by the fixpred library. *)
  | MLPASome of 'htyp ml_pat | MLPANone
and 'htyp ml_pat = ('htyp untyped_ml_pat, 'htyp) typed

type 'htyp untyped_ml_term =
(* -- Begin: used by the specification -- *)
  | MLTVar of ident
  | MLTTuple of 'htyp ml_term list
  | MLTRecord of ident list * 'htyp ml_term list
  | MLTConstr of ident * 'htyp ml_term list
  | MLTConst of ident
  | MLTFun of ident * 'htyp ml_term list * mode option
  | MLTFunNot of ident * 'htyp ml_term list * mode option
    (* The "mode option" must be None for function and Some (...) for 
       predicates. *)
(* -- End: used by the specification -- *)
  | MLTMatch of 'htyp ml_term * ('htyp ml_pat * 'htyp ml_term) list

(* Additionnal stuff *)
  (* Used for linearization. ml_terms are always variables. *)
  | MLTALin of ('htyp ml_term * 'htyp ml_term) list
  (* Output of a complete extraction (only LTrue is used) : *)
  | MLTATrue | MLTAFalse
  (* Used by the fixpred library. *)
  | MLTASome of 'htyp ml_term | MLTANone
  (* Default case in pattern matching *)
  | MLTADefault
and 'htyp ml_term = ('htyp untyped_ml_term, 'htyp) typed

(* Pretty printer *)
val pp_ml_term : 'htyp ml_term -> string
(*DEBUG*)
val pp_ml_pat : 'htyp ml_pat -> string


(******************)
(* Specifications *)
(******************)

(* A premisse in a property (or constructor) of a specification. *)
type 'htyp premisse =
  | PMTerm of 'htyp ml_term
  | PMNot of 'htyp premisse
  | PMOr of 'htyp premisse list
  | PMAnd of 'htyp premisse list
  | PMChoice of 'htyp premisse list

(* A property (or constructor) of a specification. *)
type 'htyp property = {
  prop_name : ident option;
  prop_vars : ident list;
  prop_prems : 'htyp premisse list;
  prop_concl : 'htyp ml_term;
}

(* Type of a specification. *)
type 'htyp spec = {
  spec_name : ident;
  spec_args_types : 'htyp term_type list;
  spec_props : 'htyp property list;
} 

val pp_spec : 'htyp spec -> string


(****************)
(* ML functions *)
(****************)

(* A function in the ML-like intermediate language. *)
type 'htyp ml_fun = {
  mlfun_name : ident;
  mlfun_args : ident list;
  mlfun_body : 'htyp ml_term;
}

(* Pretty printer *)
val pp_ml_fun : 'htyp ml_fun -> string


(*********)
(* Trees *)
(*********)

(* Predicate tree. Used to represent an inductive predicate before the code
   generation. *)
type 'htyp tree

(* Pretty printer *)
val pp_tree : 'htyp tree -> string


(*****************)
(* Fix functions *)
(*****************)

type 'htyp fix_untyped_term =
(* Standard constructions. *)
  | FixVar of ident
(*  | FixRecord of ident list * fix_term list*)
  | FixConstr of ident * 'htyp fix_term list
  | FixConst of ident
  | FixFun of ident * 'htyp fix_term list
  | FixFunNot of ident * 'htyp fix_term list
  | FixCase of 'htyp fix_term * (ident list * 'htyp fix_term) list
  | FixLetin of ident * 'htyp fix_term * 'htyp fix_term

(* To be converted as standard constructions. *)
  | FixSome of 'htyp fix_term
  | FixNone
  | FixTrue 
  | FixFalse 
and 'htyp fix_term = ('htyp fix_untyped_term, 'htyp) typed

type 'htyp fix_fun = {
  fixfun_name : ident;
  fixfun_args : ident list;
  fixfun_body : 'htyp fix_term;
}

val pp_fix_term : 'htyp fix_term -> string
val pp_fix_fun : 'htyp fix_fun -> string


(**************)
(* Extraction *)
(**************)

(* Extraction environment 
   This environment is used for one extraction command.
   One function or several mutualy recursive functions can be extracted.
   The mode of some other predicates can be given but they wont be extracted.
*)
type ('htyp, 'henv) extract_env = {
  (* List of modes given of every predicates. If a predicate is not present in
     this list, we assume that it is already extracted in full mode. *)
  extr_modes : (ident * mode list) list;
  (* List of predicates that will be extracted. A mode must be given for them 
     in extr_modes. The optional ident is the extracted function name. 
     The boolean flag must be true for relaxed extraction (with
     pattern ordering in pattern matchings. *)
  extr_extractions : (ident * (ident option * bool)) list;
  (* List of specification of the extracted predicates. *)
  extr_specs : (ident * 'htyp spec) list;
  (* List of predicate trees built from the specification. *)
  extr_trees : (ident * 'htyp tree) list;
  (* List of ml functions translated from the predicate trees. *)
  extr_mlfuns : (ident * 'htyp ml_fun) list;
  (* List of fix functions compiled from the ml functions. *)
  extr_fixfuns : (ident * 'htyp fix_fun) list;
  (* Environment for the host language stuff. *)
  extr_henv : 'henv host_env;
  (* Functions for the host language stuff. *)
  extr_hf : ('htyp, 'henv) host_functions;
  (* Does extracted functions need to be completed for fixpoint extraction. *)
  extr_compl : (ident * bool) list;
}

val extr_get_modes : ('t, 'h) extract_env -> ident -> mode list
val extr_get_spec : ('t, 'h) extract_env -> ident -> 't spec
val extr_get_spec_ord : ('t, 'h) extract_env -> ident -> bool
val extr_get_tree : ('t, 'h) extract_env -> ident -> 't tree
val extr_get_mlfun : ('t, 'h) extract_env -> ident -> 't ml_fun
val extr_get_fixfun : ('t, 'h) extract_env -> ident -> 't fix_fun

(* Gets the completion status of a function (for the fixpred library). *)
val get_completion_status : ('t, 'h) extract_env -> ident -> bool

val pp_extract_env : ('t, 'h) extract_env -> string

(* Get a fake type. *)
val unknown_type : ('htyp, 'henv) extract_env -> 'htyp term_type

(* Type a term with a fake type. *)
val fake_type : ('htyp, 'henv) extract_env -> 't -> ('t, 'htyp) typed

(* Extraction aborted because it's impossible to insert the property 
   in the tree. The string is the reason. *)
exception RelationExtractionProp of ident option * string
val make_trees : ('t, 'h) extract_env -> ('t, 'h) extract_env

val make_ml_funs : ('t, 'h) extract_env -> ('t, 'h) extract_env
(*val make_fix_funs : ('t, 'h) extract_env -> ('t, 'h) extract_env*)


val get_in_terms_func : ('t, 'h) extract_env -> 't ml_term -> 't ml_term list
val get_out_terms_func : ('t, 'h) extract_env -> 't ml_term -> 't ml_term list
