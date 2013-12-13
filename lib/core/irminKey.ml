(*
 * Copyright (c) 2013 Thomas Gazagnaire <thomas@gazagnaire.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

module type S = sig
  include IrminBase.S
  exception Invalid of string
  exception Unknown of string
  val of_string: string -> t
  val of_pretty: string -> t
end

module type BINARY = sig
  include S
  val of_bytes: string -> t
  val of_ba: IrminBuffer.ba -> t
  val to_hex: t -> string
  val of_hex: string -> t
end

module SHA1 = struct

  let debug fmt = IrminLog.debug "SHA1" fmt

  type t = string

  exception Invalid of string

  exception Unknown of string

  let to_string x = x

  let compare = String.compare

  let hash = Hashtbl.hash

  let equal t1 t2 = String.compare t1 t2 = 0

  let name = "key"

  let len = 20

  let of_string str =
    if String.length str = len then str
    else raise (Invalid str)

  let to_hex t =
    IrminMisc.hex_encode t

  let of_hex hex =
    IrminMisc.hex_decode hex

  let to_json t =
    Ezjsonm.string (to_hex t)

  let of_json j =
    of_hex (Ezjsonm.get_string j)

  let pretty = to_hex

  let of_pretty = of_hex

  (* |-----|-------------| *)
  (* | 'K' | PAYLOAD(20) | *)
  (* |-----|-------------| *)

  let header = "K"

  let sizeof _ =
    1 + len

  let get buf =
    debug "get";
    let h = IrminBuffer.get_string buf 1 in
    if header <> h then None
    else
      try
        let str = IrminBuffer.get_string buf len in
        debug "--> get %s" (pretty str);
        Some str
      with _ ->
        None

  let set buf t =
    debug "set %s" (pretty t);
    IrminBuffer.set_string buf header;
    IrminBuffer.set_string buf t

  let of_bytes str =
    debug "of_bytes: %S" str;
    IrminMisc.sha1 str

  let of_ba ba =
    let buf = IrminBuffer.of_ba ba in
    let len = IrminBuffer.length buf in
    let str = IrminBuffer.get_string buf len in
    of_bytes str

end
