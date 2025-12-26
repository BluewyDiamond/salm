use ../../../../error.nu [ file_errs file_oks err ok ]

export def main [
   file_spec: record
]: nothing -> record {
   try {
      link-file-spec-unsafe $file_spec
   } catch {|error|
      err -n $file_errs.CATCH -v $error
   }
}

def link-file-spec-unsafe [
   file_spec: record
]: nothing -> record {
   let source_abs_path_type = $file_spec.source_abs_path | path type
   let target_abs_path_type = $file_spec.target_abs_path | path type

   match [$source_abs_path_type $target_abs_path_type] {
      [null _] => {
         err
      }

      [_ null] => {

         let target_parent_dir_abs_path = $file_spec.target_abs_path | path dirname

         if not ($target_parent_dir_abs_path | path exists) {
            mkdir $target_parent_dir_abs_path
         }

         ln -s $file_spec.source_abs_path $file_spec.target_abs_path
         chown -R $"($file_spec.owner):($file_spec.group)" $file_spec.target_abs_path
         ok
      }

      [_ dir] => {
         rm -r $file_spec.target_abs_path
         ln -s $file_spec.source_abs_path $file_spec.target_abs_path
         chown -R $"($file_spec.owner):($file_spec.group)" $file_spec.target_abs_path
         ok
      }

      [_ file] => {
         rm $file_spec.target_abs_path
         ln -s $file_spec.source_abs_path $file_spec.target_abs_path
         chown -R $"($file_spec.owner):($file_spec.group)" $file_spec.target_abs_path
         ok
      }

      [_ symlink] => {
         if (
            ($file_spec.target_abs_path | path expand) ==
            $file_spec.source_abs_path
         ) {
            return (ok -n $file_oks.SKIPPED)
         }

         unlink $file_spec.target_abs_path
         ln -s $file_spec.source_abs_path $file_spec.target_abs_path
         chown -R $"($file_spec.owner):($file_spec.group)" $file_spec.target_abs_path
         ok
      }

      [_ _] => {
         err
      }
   }
}
