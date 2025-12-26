use ./install-file-specs/install-file-spec.nu

export def main [
   file_specs: list<record>
]: nothing -> nothing {
   if ($file_specs | is-empty) {
      return
   }

   let formatted_results = $file_specs | each {|file_spec|
      let result = install-file-spec $file_spec

      {
         target: $file_spec.target_abs_path
         status: ($result | to nuon)
      }
   }

   $formatted_results | print
}
