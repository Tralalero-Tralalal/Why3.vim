open Why3
open Format

(*This initializes a var fmla_true = true*)
let fmla_true : Term.term = Term.t_true

(*This initializes a var fmla_false = false*)
let fmla_false : Term.term = Term.t_false

(*This initializes a var fmla_true or fmla_false, which is true \/ false*)
let fmla1 : Term.term = Term.t_or fmla_true fmla_false

(*The type lsymbol is the type of function and predicate symbols, which we can call logic symbols*)
(*This initializes a var prop_var_A as a Propositional var A*)
let prop_var_A : Term.lsymbol =
  Term.create_psymbol (Ident.id_fresh "A") []

(*This initializes a var prop_var_B as a Propositional var B*)
let prop_var_B : Term.lsymbol =
  Term.create_psymbol (Ident.id_fresh "B") []

(*We apply a general function for applying lsymbol to a list of terms, we just have an empty list for now*)
let atom_A : Term.term = Term.ps_app prop_var_A []
let atom_B : Term.term = Term.ps_app prop_var_B []

(*This makes A and B implies A*)
let fmla2 : Term.term =
  Term.t_implies (Term.t_and atom_A atom_B) atom_A

let task1 : Task.task = None (* empty task *)
let goal_id1 : Decl.prsymbol = Decl.create_prsymbol (Ident.id_fresh "goal1") (*makes a goal*)
let task1 : Task.task = Task.add_prop_decl task1 Decl.Pgoal goal_id1 fmla1 (*Makes a prop of type Pgoal*)

let task2 = None (* task for formula 2 *)
let task2 = Task.add_param_decl task2 prop_var_A (* Adds A as an abstract proposiitonal symbol to task2 *)
let task2 = Task.add_param_decl task2 prop_var_B (* Adds B as an abstract proposiitonal symbol to task2 *)
let goal_id2 = Decl.create_prsymbol (Ident.id_fresh "goal2") (* Makes a goal*)
let task2 = Task.add_prop_decl task2 Decl.Pgoal goal_id2 fmla2 (*Makes a prop of type Pgoal*)

let () = printf "@[formula 1 is:@ %a@]@." Pretty.print_term fmla1;
          printf "@[formula 2 is:@ %a@]@." Pretty.print_term fmla2;
           printf "@[task 1 is:@\n%a@]@." Pretty.print_task task1;
            printf "@[task 2 created:@\n%a@]@." Pretty.print_task task2
