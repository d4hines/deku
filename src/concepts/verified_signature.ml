open Deku_crypto

type verified_signature =
  | Verified_signature of {
      key : Key.t;
      (* TODO: is this denomarlization? *)
      key_hash : Key_hash.t;
      signed_hash : BLAKE2b.t;
      signature : Signature.t;
    }

and t = verified_signature [@@deriving eq, ord]
(* TODO: is this deriving a good idea? *)

let sign hash identity =
  let key = Identity.key identity in
  let key_hash = Identity.key_hash identity in
  let signature = Identity.sign ~hash identity in
  Verified_signature { signed_hash = hash; key; key_hash; signature }

let verify signed_hash key signature =
  let key_hash = Key_hash.of_key key in
  if Signature.verify key signature signed_hash then
    Some (Verified_signature { signed_hash; key; key_hash; signature })
  else None

let key signature =
  let (Verified_signature { key; _ }) = signature in
  key

let key_hash signature =
  let (Verified_signature { key_hash; _ }) = signature in
  key_hash

let signed_hash signature =
  let (Verified_signature { signed_hash; _ }) = signature in
  signed_hash

let signature signature =
  let (Verified_signature { signature; _ }) = signature in
  signature

module Set = Set.Make (struct
  type t = verified_signature

  let compare = compare
end)
