export def get-enabled-unit-shapes [
   --user: string
]: nothing -> table {
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
