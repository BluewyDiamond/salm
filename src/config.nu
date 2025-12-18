export def build-config [
   config_dir_abs: path
]: nothing -> oneof<record, nothing> {
   let target = $config_dir_abs | path join '*' '**' '*.toml' | into glob

   ls $target | get name | reduce -f {} {|raw_config_file_rel_path config|
      let raw_config_file_abs_path = $raw_config_file_rel_path | path expand
      let raw_config = open $raw_config_file_abs_path

      let config = if $raw_config.files? != null {
         $raw_config.files | reduce -f $config {|raw_file_spec config|
            $raw_file_spec.profiles | reduce -f $config {|raw_profile config|
               upsert-config-of-file $config $raw_config_file_abs_path $raw_file_spec $raw_profile
            }
         }
      } else {
         $config
      }

      let config = if $raw_config.packages? != null {
         $raw_config.packages | reduce -f $config {|raw_package_spec config|
            $raw_package_spec.profiles | reduce -f $config {|raw_profile config|
               upsert-config-of-package $config $raw_config_file_abs_path $raw_package_spec $raw_profile
            }
         }
      } else {
         $config
      }

      let config = if $raw_config.units? != null {
         $raw_config.units | reduce -f $config {|raw_unit_spec config|
            $raw_unit_spec.profiles | reduce -f $config {|raw_profile config|
               upsert-config-of-unit $config $raw_unit_spec $raw_profile
            }
         }
      } else {
         $config
      }

      $config
   }
}

def upsert-config-of-file [
   config: record
   raw_config_file_abs_path: path
   raw_file_spec: record
   raw_profile: string
]: nothing -> record {
   let source_abs_path = (
      $raw_config_file_abs_path
      | path dirname
      | path join $raw_file_spec.source
      | path expand
   )

   let file_spec = {
      source_abs_path: $source_abs_path
      target_abs_path: $raw_file_spec.target
      action: $raw_file_spec.action
      chmod: $raw_file_spec.chmod
      owner: $raw_file_spec.owner
      group: $raw_file_spec.group
   }

   let at = ([$raw_profile file_specs] | into cell-path)
   let file_specs = $config | get -o $at | default [] | append $file_spec
   $config | upsert $at $file_specs
}

def upsert-config-of-package [
   config: record
   raw_config_file_abs_path: path
   raw_package_spec: record
   raw_profile: string
]: nothing -> record {
   let package_specs = $raw_package_spec.install | each {|raw_package|
      let path = if $raw_package.path? != null {
         $raw_config_file_abs_path
         | path dirname
         | path join $raw_package.path
         | path expand
      }

      {
         from: $raw_package.from
         name: $raw_package.name
         ignore: ($raw_package.ignore? | default false)
         path: $path
      }
   }

   let at = ([$raw_profile package_shapes] | into cell-path)
   let package_specs = $config | get -o $at | default [] | append $package_specs
   $config | upsert $at $package_specs
}

def upsert-config-of-unit [
   config: record
   raw_unit_spec: record
   raw_profile: string
]: nothing -> record {
   let at = ([$raw_profile unit_specs] | into cell-path)

   let unit_spec = $config
   | get -o $at
   | default []
   | where {|unit_spec|
      $unit_spec.user == $raw_unit_spec.user
   } | first
   | default {
      user: $raw_unit_spec.user
   }

   let unit_spec = if $raw_unit_spec.mask? != null {
      let units_to_mask = $unit_spec.mask? | default [] | append $raw_unit_spec.mask
      $unit_spec | upsert mask $units_to_mask
   } else {
      $unit_spec
   }

   let unit_spec = if $raw_unit_spec.enable? != null {
      let units_to_enable = $unit_spec.enable? | default [] | append $raw_unit_spec.enable
      $unit_spec | upsert enable $units_to_enable
   } else {
      $unit_spec
   }

   let unit_specs = $config | get -o $at | default []

   let unit_specs = if ($unit_specs | is-not-empty) {
      $unit_specs | each {|inner_unit_spec|
         if $inner_unit_spec.user != $unit_spec.user {
            return $inner_unit_spec
         }

         $unit_spec
      }
   } else {
      [$unit_spec]
   }

   $config | upsert $at $unit_specs
}
