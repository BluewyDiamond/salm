use ../error.nu [ ok err unit_oks unit_errs ]

export def do-unit-shapes [
   unit_shapes: table
]: nothing -> nothing {
   $unit_shapes | each {|unit_shape|
      enable-units $unit_shape.user ...$unit_shape.enable
   }
}

export def cleanup-unit-shapes [
   unit_shapes: table
]: nothing -> nothing {
   $unit_shapes | each {|unit_shape|
      cleanup-unit-shape $unit_shape.user ...$unit_shape.enable
   }
}

def cleanup-unit-shape [
   user: string
   ...units_to_keep: string
]: nothing -> nothing {

   let enabled_unit_shapes = get-enabled-unit-shapes --user=$user

   let status_for_user = $enabled_unit_shapes | each {|enabled_unit_shape|
      let unit_dependencies_to_keep = $units_to_keep | each --flatten {|unit_to_keep|
         list-dependencies --user=$user $unit_to_keep
      }

      let unit_dependencies = (
         list-dependencies --user=$user $enabled_unit_shape.unit_file
      )

      let has_enabled_unit_depedencies_in_units_to_keep_and_its_dependencies = $unit_dependencies
      | any {|unit_dependency|
         (
            ($unit_dependency in $units_to_keep) or
            ($unit_dependency in $unit_dependencies_to_keep)
         )
      }

      if (
         ($enabled_unit_shape.unit_file in $units_to_keep) or
         ($enabled_unit_shape.unit_file in $unit_dependencies_to_keep) or
         $has_enabled_unit_depedencies_in_units_to_keep_and_its_dependencies
      ) {
         return {
            unit: $enabled_unit_shape.unit_file

            status: (
               ok -n $unit_oks.SKIPPED | to nuon
            )
         }
      }

      let unit_disable_result = disable-unit --user=$user $enabled_unit_shape.unit_file

      {
         unit: $enabled_unit_shape.unit_file
         status: ($unit_disable_result | to nuon)
      }
   }

   $status_for_user | print
}

def list-reverse-dependencies [
   --user: string
   unit: string
]: nothing -> list {
   let reverse_dependencies = if $user == null or $user == 'root' {
      systemctl list-dependencies --reverse --plain $unit
   } else {
      systemctl -M $"($user)@" --user list-dependencies --reverse --plain $unit
   }
   | lines
   | each {|line| $line | str trim }
   | where {|dependency|
      (
         ($dependency | str ends-with '.service') or
         ($dependency | str ends-with '.timer') or
         ($dependency | str ends-with '.socket') or
         ($dependency | str ends-with '.path')
      )
   }
   | skip 1

   $reverse_dependencies
}

def list-dependencies [
   --user: string
   unit: string
]: nothing -> list {
   let dependency = if $user == null or $user == 'root' {
      systemctl list-dependencies --plain $unit
   } else {
      systemctl -M $"($user)@" --user list-dependencies --plain $unit
   }
   | lines
   | each {|line| $line | str trim }
   | where {|dependency|
      (
         ($dependency | str ends-with '.service') or
         ($dependency | str ends-with '.timer') or
         ($dependency | str ends-with '.socket') or
         ($dependency | str ends-with '.path')
      )
   }
   | skip 1

   $dependency
}

def enable-units [
   user: string
   ...units: string
]: nothing -> nothing {
   let enabled_unit_shapes = get-enabled-unit-shapes --user $user

   let status = $units | each {|unit|
      if ($unit in $enabled_unit_shapes.unit_file) {
         return {
            unit: $unit
            status: (ok -n $unit_oks.SKIPPED | to nuon)
         }
      }

      let result = enable-unit --user=$user $unit

      {
         unit: $unit
         status: ($result | to nuon)
      }
   }

   $status | print
}

def enable-unit [
   --user: string
   unit: string
]: nothing -> record {
   try {
      if $user == null or $user == 'root' {
         systemctl enable $unit e>| ignore
      } else {
         systemctl -M $"($user)@" --user enable $unit e>| ignore
      }

      ok
   } catch {|error|
      err -n $unit_errs.CATCH -v $error
   }
}

def disable-unit [
   --user: string
   unit: string
]: nothing -> record {
   try {
      if $user == null or $user == 'root' {
         systemctl disable $unit e>| ignore
      } else {
         systemctl -M $"($user)@" --user disable $unit e>| ignore
      }

      ok
   } catch {|error|
      err -n $unit_errs.CATCH -v $error
   }
}

def get-enabled-unit-shapes [
   --user: string
]: nothing -> table {
   def list-unit-files [
      --user: string
   ]: nothing -> table {
      if $user == null or $user == 'root' {
         systemctl list-unit-files --type=service,timer,socket,path --state=enabled --output=json | from json
      } else {
         systemctl -M $"($user)@" --user list-unit-files --type=service,timer,socket,path --state=enabled --output=json | from json
      }
   }

   def list-units [
      --user: string
      ...target: string
   ]: nothing -> table {
      if $user == null or $user == 'root' {
         systemctl list-units ...$target --output=json | from json
      } else {
         systemctl -M $"($user)@" --user list-units ...$target --output=json | from json
      }
   }

   let unit_shape_ones = list-unit-files --user=$user

   let unit_shape_ones = $unit_shape_ones
   | each --flatten {|unit_shape_one|
      if not ($unit_shape_one.unit_file | str contains '@') {
         return $unit_shape_one
      }

      let unit_name_wildcard = ($unit_shape_one.unit_file | str replace @ @*)
      let unit_shape_twos = list-units --user=$user $unit_name_wildcard

      $unit_shape_twos
      | each {|unit_shape_two|
         {
            unit_file: $unit_shape_two.unit
            state: $unit_shape_one.state
            preset: $unit_shape_one.preset
         }
      }
   }

   $unit_shape_ones
}
