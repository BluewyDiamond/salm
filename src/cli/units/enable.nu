use ../../error.nu [ ok err unit_oks unit_errs ]
use ./common/enabled.nu get-enabled-unit-shapes

export def enable-units [
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
