export const file_oks = {
   SKIPPED: "SKIPPED"
}

export const file_errors = {
   ANY: "ANY"
}

export def ok [
   -n: oneof<string, nothing> # name
   -v: any # value
]: nothing -> record {
   {
      ok: {
         name: $n
         value: $v
      }
   }
}

export def err [
   -n: oneof<string, nothing> # name
   -v: any # value
]: nothing -> record {
   {
      err: {
         name: $n
         value: $v
      }
   }
}
