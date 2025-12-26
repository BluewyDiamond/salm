use ../error.nu [ ok err file_oks file_errs ]

export def install-file-specs [
   file_specs: list<record>
]: nothing -> nothing {
   if ($file_specs | is-empty) {
      return
   }

   let formatted_results = $file_specs | each {|file_spec|
      let result = install-file-shape $file_spec

      {
         target: $file_spec.target_abs_path
         status: ($result | to nuon)
      }
   }

   $formatted_results | print
}

def install-file-shape [
   file_spec: record
]: nothing -> record {
   match $file_spec.action {
      copy => {
         copy-file-shape $file_spec
      }

      link => {
         link-file-shape $file_spec
      }

      _ => {
         err -n $file_errs.PATTERN -v $file_spec.action
      }
   }
}

def copy-file-shape [
   file_spec: record
]: nothing -> record {
   try {
      copy-file-shape-unsafe $file_spec
   } catch {|error|
      err -n $file_errs.CATCH -v $error
   }
}

def copy-file-shape-unsafe [
   file_shape: record
]: nothing -> record {
   let source_abs_path_type = $file_shape.source_abs_path | path type
   let target_abs_path_type = $file_shape.target_abs_path | path type

   match [$source_abs_path_type $target_abs_path_type] {
      [null _] => {
         return (err)
      }

      [_ null] => {
         let target_dir_abs_path = $file_shape.target_abs_path | path dirname

         if not ($target_dir_abs_path | path exists) {
            mkdir $target_dir_abs_path
         }

         cp -r $file_shape.source_abs_path $file_shape.target_abs_path
         chmod $file_shape.chmod $file_shape.target_abs_path
         chown -R $"($file_shape.owner):($file_shape.group)" $file_shape.target_abs_path
         ok
      }

      [dir dir] => {
         if (
            diff
            -rq
            $file_shape.target_abs_path
            $file_shape.source_abs_path
            | complete
            | get exit_code
            | $in == 0
         ) {
            return (ok -n $file_oks.SKIPPED)
         }

         rm -r $file_shape.target_abs_path
         cp -r $file_shape.source_abs_path $file_shape.target_abs_path
         chmod $file_shape.chmod $file_shape.target_abs_path
         chown -R $"($file_shape.owner):($file_shape.group)" $file_shape.target_abs_path
         ok
      }

      [file file] => {
         let target_file = open --raw $file_shape.target_abs_path
         let source_file = open --raw $file_shape.source_abs_path

         if ($target_file == $source_file) {
            return (ok -n $file_oks.SKIPPED)
         }

         rm $file_shape.target_abs_path
         cp $file_shape.source_abs_path $file_shape.target_abs_path
         chmod $file_shape.chmod $file_shape.target_abs_path
         chown -R $"($file_shape.owner):($file_shape.group)" $file_shape.target_abs_path
         ok
      }

      [symlink symlink] => {
         if (
            ($file_shape.source_abs_path | path expand) ==
            ($file_shape.target_abs_path | path expand)
         ) {
            return (ok -n $file_oks.SKIPPED)
         }

         unlink $file_shape.target_abs_path
         cp $file_shape.source_abs_path $file_shape.target_abs_path
         chmod $file_shape.chmod $file_shape.target_abs_path
         chown -R $"($file_shape.owner):($file_shape.group)" $file_shape.target_abs_path
         ok
      }

      [_ _] => {
         err
      }
   }
}

def link-file-shape [
   file_shape: record
]: nothing -> record {
   try {
      link-file-shape-unsafe $file_shape
   } catch {|error|
      err -n $file_errs.CATCH -v $error
   }
}

def link-file-shape-unsafe [
   file_shape: record
]: nothing -> record {
   let source_abs_path_type = $file_shape.source_abs_path | path type
   let target_abs_path_type = $file_shape.target_abs_path | path type

   match [$source_abs_path_type $target_abs_path_type] {
      [null _] => {
         err
      }

      [_ null] => {

         let target_parent_dir_abs_path = $file_shape.target_abs_path | path dirname

         if not ($target_parent_dir_abs_path | path exists) {
            mkdir $target_parent_dir_abs_path
         }

         ln -s $file_shape.source_abs_path $file_shape.target_abs_path
         chown -R $"($file_shape.owner):($file_shape.group)" $file_shape.target_abs_path
         ok
      }

      [_ dir] => {
         rm -r $file_shape.target_abs_path
         ln -s $file_shape.source_abs_path $file_shape.target_abs_path
         chown -R $"($file_shape.owner):($file_shape.group)" $file_shape.target_abs_path
         ok
      }

      [_ file] => {
         rm $file_shape.target_abs_path
         ln -s $file_shape.source_abs_path $file_shape.target_abs_path
         chown -R $"($file_shape.owner):($file_shape.group)" $file_shape.target_abs_path
         ok
      }

      [_ symlink] => {
         if (
            ($file_shape.target_abs_path | path expand) ==
            $file_shape.source_abs_path
         ) {
            return (ok -n $file_oks.SKIPPED)
         }

         unlink $file_shape.target_abs_path
         ln -s $file_shape.source_abs_path $file_shape.target_abs_path
         chown -R $"($file_shape.owner):($file_shape.group)" $file_shape.target_abs_path
         ok
      }

      [_ _] => {
         err
      }
   }
}
