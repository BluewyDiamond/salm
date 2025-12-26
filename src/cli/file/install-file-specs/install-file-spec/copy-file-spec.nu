use ../../../../error.nu [ file_errs file_oks err ok]

export def main [
   file_spec: record
]: nothing -> record {
   try {
      copy-file-shape-unsafe $file_spec
   } catch {|error|
      err -n $file_errs.CATCH -v $error
   }
}

def copy-file-shape-unsafe [
   file_spec: record
]: nothing -> record {
   let source_abs_path_type = $file_spec.source_abs_path | path type
   let target_abs_path_type = $file_spec.target_abs_path | path type

   match [$source_abs_path_type $target_abs_path_type] {
      [null _] => {
         return (err)
      }

      [_ null] => {
         let target_dir_abs_path = $file_spec.target_abs_path | path dirname

         if not ($target_dir_abs_path | path exists) {
            mkdir $target_dir_abs_path
         }

         cp -r $file_spec.source_abs_path $file_spec.target_abs_path
         chmod $file_spec.chmod $file_spec.target_abs_path
         chown -R $"($file_spec.owner):($file_spec.group)" $file_spec.target_abs_path
         ok
      }

      [dir dir] => {
         if (
            diff
            -rq
            $file_spec.target_abs_path
            $file_spec.source_abs_path
            | complete
            | get exit_code
            | $in == 0
         ) {
            return (ok -n $file_oks.SKIPPED)
         }

         rm -r $file_spec.target_abs_path
         cp -r $file_spec.source_abs_path $file_spec.target_abs_path
         chmod $file_spec.chmod $file_spec.target_abs_path
         chown -R $"($file_spec.owner):($file_spec.group)" $file_spec.target_abs_path
         ok
      }

      [file file] => {
         let target_file = open --raw $file_spec.target_abs_path
         let source_file = open --raw $file_spec.source_abs_path

         if ($target_file == $source_file) {
            return (ok -n $file_oks.SKIPPED)
         }

         rm $file_spec.target_abs_path
         cp $file_spec.source_abs_path $file_spec.target_abs_path
         chmod $file_spec.chmod $file_spec.target_abs_path
         chown -R $"($file_spec.owner):($file_spec.group)" $file_spec.target_abs_path
         ok
      }

      [symlink symlink] => {
         if (
            ($file_spec.source_abs_path | path expand) ==
            ($file_spec.target_abs_path | path expand)
         ) {
            return (ok -n $file_oks.SKIPPED)
         }

         unlink $file_spec.target_abs_path
         cp $file_spec.source_abs_path $file_spec.target_abs_path
         chmod $file_spec.chmod $file_spec.target_abs_path
         chown -R $"($file_spec.owner):($file_spec.group)" $file_spec.target_abs_path
         ok
      }

      [_ _] => {
         err
      }
   }
}
