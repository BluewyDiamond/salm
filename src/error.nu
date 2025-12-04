# when pattern matching, check wether if it ok or err variant
# and make sure name is not null, the same for value

export const file_oks = {
   SKIPPED: "SKIPPED"
}

export const file_errs = {
   PATTERN: "PATTERN"
   CATCH: "CATCH"
}

export const unit_oks = {
   SKIPPED: "SKIPPED"
}

export const unit_errs = {
   CATCH: "CATCH"
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
