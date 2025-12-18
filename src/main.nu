use ./config.nu [ build-config ]
use ./cli/files.nu [ install-file-shapes ]
use ./cli/packages/install-pkg-shapes.nu
use ./cli/packages/cleanup-pkg-shapes.nu
use ./cli/units/do-unit-shapes.nu
use ./cli/units/cleanup-unit-shape.nu

# Reads *.toml recursively and does stuff.
def main [] { }

def 'main list' [
   --config-dir (-c): path = . # full path to config directory
]: nothing -> list {
   build-config $config_dir | columns | sort
}

def 'main show' [
   --config-dir (-c): path = . # full path to config directory
   ...profiles: string # list of profile names
]: nothing -> record {
   let profiles = $profiles | each {|profile| [$profile] | into cell-path }
   let config = build-config $config_dir
   let config = $config | get ($profiles | first) ...($profiles | drop 1)
   $config
}

def 'main install' [
   --config-dir (-c): path = . # full path to config directory
   ...profiles: string # list of profile names
]: nothing -> nothing {
   let profiles = $profiles | each {|profile| [$profile] | into cell-path }
   let config = build-config $config_dir
   let config = $config | get ($profiles | first) ...($profiles | drop 1)

   if $config.file_shapes? != null {
      install-file-shapes $config.file_shapes
   }

   if $config.package_shapes? != null {
      install-pkg-shapes $config.package_shapes
   }

   if $config.unit_shapes? != null {
      do-unit-shapes $config.unit_shapes
   }

   null
}

def 'main cleanup' [
   --config-dir (-c): path = . # full path to config directory
   ...profiles: string # list of profile names
]: nothing -> nothing {
   let profiles = $profiles | each {|profile| [$profile] | into cell-path }
   let config = build-config $config_dir
   let config = $config | get ($profiles | first) ...($profiles | drop 1)

   do {
      if $config.package_shapes? == null or ($config.package_shapes | is-empty) {
         return
      }

      cleanup-pkg-shapes $config.package_shapes | table -e | print
   }

   do {
      if $config.unit_shapes? == null or ($config.unit_shapes | is-empty) {
         return
      }

      cleanup-unit-shapes $config.unit_shapes
   }

   null
}
