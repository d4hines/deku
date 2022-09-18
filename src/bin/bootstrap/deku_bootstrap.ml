open Deku_stdlib
open Deku_crypto
open Deku_consensus
open Deku_gossip
open Deku_network

let restart network =
  let _message, raw_message =
    Message.encode
      ~content:
        (Message.Content.bootstrap_signal Bootstrap_signal.Bootstrap_signal)
  in
  let (Raw_message { hash; raw_content }) = raw_message in
  let raw_expected_hash = Message_hash.to_b58 hash in
  Network.broadcast ~raw_expected_hash ~raw_content network

let bootstrap validators validator_uris =
  let validators = List.map2 (fun a b -> (a, b)) validators validator_uris in
  let network = Network.connect ~nodes:validators in
  (* TODO: remove this sleep *)
  let%await () = Lwt_unix.sleep 3.0 in
  let () = restart network in
  (* TODO: this is lame, but Lwt*)
  let%await () = Lwt_unix.sleep 3.0 in
  Lwt.return (Ok ())

open Cmdliner

(* TODO: extract some of this stuff into a library
   of Cmdliner helpers (e.g. Uri parser, etc.) *)

(* TODO: is there a better pattern for dealing with Lwt and Cmdliner? *)
let lwt_ret p =
  let open Term in
  term_result' (const Lwt_main.run $ p)

let exits =
  Cmd.Exit.defaults
  @ [ Cmd.Exit.info 1 ~doc:"expected failure (might not be a bug)" ]

let man =
  [ `S Manpage.s_bugs; `P "Email bug reports to <contact@marigold.dev>." ]

let uri =
  let parser uri = Ok (uri |> Uri.of_string) in
  let printer ppf uri = Format.fprintf ppf "%s" (uri |> Uri.to_string) in
  let open Arg in
  conv (parser, printer)

let key_hash =
  let parser key_hash =
    match Key_hash.of_b58 key_hash with
    | Some key_hash -> Ok key_hash
    | None ->
        Error (`Msg (Format.sprintf "Unable to parse key hash '%s'" key_hash))
  in
  let printer ppf key_hash =
    Format.fprintf ppf "%s" (key_hash |> Key_hash.to_b58)
  in
  let open Arg in
  conv (parser, printer)

let info =
  let doc = "Shows identity key and address of the node." in
  Cmd.info "deku-bootstrap" ~version:"%\226\128\140%VERSION%%" ~doc ~man ~exits

let term =
  let validators =
    let open Arg in
    let docv = "validators" in
    let doc = "Comma-separated list of validator public key hashes" in
    let env = Cmd.Env.info "DEKU_VALIDATORS" in
    required
    & opt (some (list key_hash)) None
    & info [ "validators" ] ~doc ~docv ~env
  in
  let validator_uris =
    let open Arg in
    let docv = "validator_uris" in
    let doc =
      "Comma-separated list of validator URI's to which to broadcast operations"
    in

    let env = Cmd.Env.info "DEKU_VALIDATOR_URIS" in
    required
    & opt (some (list uri)) None
    & info [ "validator-uris" ] ~doc ~docv ~env
  in
  let open Term in
  lwt_ret (const bootstrap $ validators $ validator_uris)

let _ = Cmd.eval ~catch:true @@ Cmd.v info term
