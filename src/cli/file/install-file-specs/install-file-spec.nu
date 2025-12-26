use ../../../error.nu [ file_errs ]
use ./install-file-spec/copy-file-spec.nu
use ./install-file-spec/link-file-spec.nu

export def main [
   file_spec: record
]: nothing -> record {
   match $file_spec.action {
      copy => {
         copy-file-spec $file_spec
      }

      link => {
         link-file-spec $file_spec
      }

      _ => {
         err -n $file_errs.PATTERN -v $file_spec.action
      }
   }
}
