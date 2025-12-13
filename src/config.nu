export def build-config [
   config_dir_abs: path
]: nothing -> oneof<table, nothing> {
   let target = $config_dir_abs | path join '*' '**' '*.toml' | into glob

   let config = ls $target
   | get name
   | reduce -f {} {|raw_config_file_rel_path config|
      let raw_config_file_abs_path = $raw_config_file_rel_path | path expand
      let raw_config = open $raw_config_file_abs_path

      mut config = $config

      if $raw_config.files? != null {
         $config = $raw_config.files | reduce -f $config {|raw_file config|
            $raw_file.profiles | reduce -f $config {|raw_profile config|
               let file_shapes = $config
               | get -o $raw_profile
               | get -o file_shapes
               | default []

               let new_file_shape = {
                  source_abs_path: (
                     $raw_config_file_abs_path
                     | path dirname
                     | path join $raw_file.source
                     | path expand
                  )

                  target_abs_path: $raw_file.target
                  action: $raw_file.action
                  chmod: $raw_file.chmod
                  owner: $raw_file.owner
                  group: $raw_file.group
               }

               let file_shapes = $file_shapes | append $new_file_shape
               let at = ([$raw_profile file_shapes] | into cell-path)
               $config | upsert $at $file_shapes
            }
         }
      }

      if $raw_config.packages? != null {
         $config = $raw_config.packages | reduce -f $config {|raw_package config|
            $raw_package.profiles | reduce -f $config {|raw_profile config|
               let package_shapes = $config
               | get -o $raw_profile
               | get -o package_shapes
               | default []

               let new_package_shapes = $raw_package.install | each {|raw_package|
                  {
                     from: $raw_package.from
                     name: $raw_package.name
                     ignore: ($raw_package.ignore? | default false)

                     path: (
                        if $raw_package.path? != null {
                           $raw_config_file_abs_path
                           | path dirname
                           | path join $raw_package.path
                           | path expand
                        }
                     )
                  }
               }

               let package_shapes = $package_shapes | append $new_package_shapes
               let at = ([$raw_profile package_shapes] | into cell-path)
               $config | upsert $at $package_shapes
            }
         }
      }

      if $raw_config.units? != null {
         $config = $raw_config.units | reduce -f $config {|raw_unit config|
            $raw_unit.profiles | reduce -f $config {|raw_profile config|
               mut unit_shapes = $config
               | get -o $raw_profile
               | get -o unit_shapes
               | default []

               let new_unit_shape = {
                  user: $raw_unit.user
                  mask: $raw_unit.mask?
                  enable: $raw_unit.enable?
               }

               let user_matching_unit_shape = $unit_shapes | any {|unit_shape|
                  $unit_shape.user == $new_unit_shape.user
               }

               if $user_matching_unit_shape {
                  $unit_shapes = $unit_shapes | each {|unit_shape|
                     if $unit_shape.user != $new_unit_shape.user {
                        return $unit_shape
                     }

                     {
                        user: $unit_shape.user
                        mask: ($raw_unit.mask? | append $new_unit_shape.mask)
                        enable: ($raw_unit.enable | append $new_unit_shape.enable)
                     }
                  }
               } else {
                  $unit_shapes = $unit_shapes | append $new_unit_shape
               }

               let at = ([$raw_profile unit_shapes] | into cell-path)
               $config | upsert $at $unit_shapes
            }
         }
      }

      $config
   }

   $config
}
