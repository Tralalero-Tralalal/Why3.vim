open Why3

(* a ground propositional goal: true or false *)
let fmla_true : Term.term = Term.t_true
let fmla_false : Term.term = Term.t_false
let fmla1 : Term.term = Term.t_or fmla_true fmla_false

open Format
let () = printf "@[formula 1 is:@ %a@]@." Pretty.print_term fmla1
