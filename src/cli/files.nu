export def install-file-shapes [
   file_shapes: oneof<table, nothing>
]: nothing -> nothing {
   if $file_shapes == null or ($file_shapes | is-empty) {
      return
   }

   $file_shapes | each {|file_shape|
      let install_result = install-file-shape $file_shape

      {
         target: $file_shape.target_abs_path
         status: $install_result.status
      }
   } | print
}

def install-file-shape [
   file_shape: record
]: nothing -> record<status: string> {
   match $file_shape.action {
      copy => {
         copy-file-shape $file_shape
      }

      link => {
         link-file-shape $file_shape
      }

      _ => {
         {status: 'failed'}
      }
   }
}

def copy-file-shape [
   file_shape: record
]: nothing -> record<status: string> {
   let source_abs_path_type = $file_shape.source_abs_path | path type
   let target_abs_path_type = $file_shape.target_abs_path | path type

   try {
      match [$source_abs_path_type $target_abs_path_type] {
         [null _] => {
            {status: 'failed'}
         }

         [_ null] => {
            let target_dir_abs_path = $file_shape.target_abs_path | path dirname

            if not ($target_dir_abs_path | path exists) {
               mkdir $target_dir_abs_path
            }

            cp -r $file_shape.source_abs_path $file_shape.target_abs_path
            chmod $file_shape.chmod $file_shape.target_abs_path
            chown -R $"($file_shape.owner):($file_shape.group)" $file_shape.target_abs_path
            {status: 'success'}
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
               return {status: 'skipped'}
            }

            rm -r $file_shape.target_abs_path
            cp -r $file_shape.source_abs_path $file_shape.target_abs_path
            chmod $file_shape.chmod $file_shape.target_abs_path
            chown -R $"($file_shape.owner):($file_shape.group)" $file_shape.target_abs_path
            {status: 'success'}
         }

         [file file] => {
            let target_file = open --raw $file_shape.target_abs_path
            let source_file = open --raw $file_shape.source_abs_path

            if ($target_file == $source_file) {
               return {status: 'skipped'}
            }

            rm $file_shape.target_abs_path
            cp $file_shape.source_abs_path $file_shape.target_abs_path
            chmod $file_shape.chmod $file_shape.target_abs_path
            chown -R $"($file_shape.owner):($file_shape.group)" $file_shape.target_abs_path
            {status: 'success'}
         }

         [symlink symlink] => {
            if (
               ($file_shape.source_abs_path | path expand) ==
               ($file_shape.target_abs_path | path expand)
            ) {
               return {status: 'skipped'}
            }

            unlink $file_shape.target_abs_path
            cp $file_shape.source_abs_path $file_shape.target_abs_path
            chmod $file_shape.chmod $file_shape.target_abs_path
            chown -R $"($file_shape.owner):($file_shape.group)" $file_shape.target_abs_path
            {status: 'success'}
         }

         [_ _] => {
            {status: 'failed'}
         }
      }
   } catch {
      {status: 'failed'}
   }
}

def link-file-shape [
   file_shape: record
]: nothing -> record<status: string> {
   let source_abs_path_type = $file_shape.source_abs_path | path type
   let target_abs_path_type = $file_shape.target_abs_path | path type

   try {
      match [$source_abs_path_type $target_abs_path_type] {
         [null _] => {
            {status: 'failed'}
         }

         [_ null] => {

            let target_parent_dir_abs_path = $file_shape.target_abs_path | path dirname

            if not ($target_parent_dir_abs_path | path exists) {
               mkdir $target_parent_dir_abs_path
            }

            ln -s $file_shape.source_abs_path $file_shape.target_abs_path
            chown -R $"($file_shape.owner):($file_shape.group)" $file_shape.target_abs_path
            {status: 'success'}
         }

         [_ dir] => {
            rm -r $file_shape.target_abs_path
            ln -s $file_shape.source_abs_path $file_shape.target_abs_path
            chown -R $"($file_shape.owner):($file_shape.group)" $file_shape.target_abs_path
            {status: 'success'}
         }

         [_ file] => {
            rm $file_shape.target_abs_path
            ln -s $file_shape.source_abs_path $file_shape.target_abs_path
            chown -R $"($file_shape.owner):($file_shape.group)" $file_shape.target_abs_path
            {status: 'success'}
         }

         [_ symlink] => {
            if (
               ($file_shape.target_abs_path | path expand) ==
               $file_shape.source_abs_path
            ) {
               return {status: 'skipped'}
            }

            unlink $file_shape.target_abs_path
            ln -s $file_shape.source_abs_path $file_shape.target_abs_path
            chown -R $"($file_shape.owner):($file_shape.group)" $file_shape.target_abs_path
            {status: 'success'}
         }

         [_ _] => {
            {status: 'failed'}
         }
      }
   } catch {
      {status: 'failed'}
   }
}
