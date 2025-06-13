open Why3
open Format
open Itp_server
open Itp_communication
open Whyconf

exception Badparsing

let print_request_json fmt (r : ide_request) =
  (try
     let s = Pp.string_of Json_util.print_request r in
     let x = Json_util.parse_request s in
     if r = x then
       ()
     else
       raise Badparsing
   with
  | _ -> Format.eprintf "Bad parsing@.");
  Json_util.print_request fmt r

let print_notification_json fmt (n : notification) =
  (try
     let x =
       Json_util.parse_notification
         (Pp.string_of Json_util.print_notification n)
     in
     if n = x then
       ()
     else
       raise Badparsing
   with
  | _ -> Format.eprintf "Bad parsing@.");
  Json_util.print_notification fmt n

let debug_json =
  Debug.register_flag "json_proto"
    ~desc:"Print@ json@ requests@ and@ notifications@"

(*Protocol Module*)
module Protocol_why3ide = struct
  let debug_proto =
    Debug.register_flag "ide_proto"
      ~desc:"Print@ debugging@ messages@ about@ Why3Ide@ protocol@"

  let print_request_debug r =
    Debug.dprintf debug_proto "request %a@." print_request r;
    Debug.dprintf debug_json "%a@." print_request_json r

  let print_notify_debug n =
    Debug.dprintf debug_proto "handling notification %a@." print_notify n;
    Debug.dprintf debug_json "%a@." print_notification_json n

  let list_requests : ide_request list ref = ref []

  let get_requests () =
    let n = List.length !list_requests in
    if n > 0 then Debug.dprintf debug_proto "got %d new requests@." n;
    let l = List.rev !list_requests in
    list_requests := [];
    l

  let send_request r =
    print_request_debug r;
    list_requests := r :: !list_requests

  let notification_list : notification list ref = ref []

  let notify n =
    (* too early, print when handling notifications print_notify_debug n; *)
    notification_list := n :: !notification_list

  let get_notified () =
    let n = List.length !notification_list in
    if n > 0 then Debug.dprintf debug_proto "got %d new notifications@." n;
    let l = List.rev !notification_list in
    notification_list := [];
    l
end
(*Protocol Module*)

(* The gtk scheduler is catching all exceptions avoiding the printing of the
   backtrace that is normally done by debug option stack_trace. To recover this
   behavior we catch exceptions ourselves. If "stack_trace" is on, we exit on
   first exception and print backtrace on standard output otherwise we raise the
   exception again (with information on error output). *)
let backtrace_and_exit f () =
  try f () with
  | e ->
    if Debug.test_flag Debug.stack_trace then (
      Printexc.print_backtrace stderr;
      Format.eprintf "exception '%a' was raised in a LablGtk callback.@."
        Exn_printer.exn_printer e;
      exit 1
    ) else (
      Format.eprintf "exception '%a' was raised in a LablGtk callback.@."
        Exn_printer.exn_printer e;
      Format.eprintf "This should not happen. Please report. @.";
      raise e
    )

module Scheduler = struct
  let blocking = false
  let multiplier = 3

  let idle ~prio f =
    let (_ : GMain.Idle.id) = GMain.Idle.add ~prio (backtrace_and_exit f) in
    ()

  let timeout ~ms f =
    let (_ : GMain.Timeout.id) =
      GMain.Timeout.add ~ms ~callback:(backtrace_and_exit f)
    in
    ()
end

module Server = Itp_server.Make (Scheduler) (Protocol_why3ide)

let config = Whyconf.init_config (Some ".why3.conf")
let main : Whyconf.main = Whyconf.get_main config
let env : Env.env = Env.create_env (Whyconf.loadpath main)

let () =
  Server.init_server config env "/home/humam/Projects/my-projects/why3.nvim/hello";
