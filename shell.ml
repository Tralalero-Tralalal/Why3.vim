open Why3
open Format
open Itp_server
open Itp_communication
open Whyconf
open Unix_scheduler

module Protocol_shell = struct

  let debug_proto = Debug.register_flag "shell_proto"
      ~desc:"Print@ debugging@ messages@ about@ Why3Ide@ protocol@"

  let (_: unit) = Debug.unset_flag debug_proto

  let print_request_debug r =
    Debug.dprintf debug_proto "[request]";
    Debug.dprintf debug_proto "%a" print_request r

  let print_notify_debug n =
    Debug.dprintf debug_proto "[notification]";
    Debug.dprintf debug_proto "%a@." print_notify n

  let list_requests: ide_request list ref = ref []

  let get_requests () =
    if List.length !list_requests > 0 then
      Debug.dprintf debug_proto "get requests@.";
    let l = List.rev !list_requests in
    list_requests := [];
    l

  let send_request r =
    print_request_debug r;
    Debug.dprintf debug_proto "@.";
    list_requests := r :: !list_requests

  let notification_list: notification list ref = ref []

  let notify n =
    print_notify_debug n;
    Debug.dprintf debug_proto "@.";
    notification_list := n :: !notification_list

  let get_notified () =
    if List.length !notification_list > 0 then
      Debug.dprintf debug_proto "get notified@.";
    let l = List.rev !notification_list in
    notification_list := [];
    l

end

let get_notified = Protocol_shell.get_notified

let send_request = Protocol_shell.send_request

module Server = Itp_server.Make (Unix_scheduler) (Protocol_shell)

let config = Whyconf.init_config None
let main : Whyconf.main = Whyconf.get_main config
let env : Env.env = Env.create_env (Whyconf.loadpath main)

let () =
  Server.init_server config env "/home/humam/Projects/my-projects/why3.nvim/hello";
