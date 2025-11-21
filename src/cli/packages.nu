export def install-package-shapes [
   package_shapes: oneof<table, nothing>
]: nothing -> nothing {
   if $package_shapes == null or ($package_shapes | is-empty) {
      return
   }

   let installed_packages = pacman -Qq | lines

   let missing_package_shapes = $package_shapes | where {|package_shape|
      ($package_shape.name not-in $installed_packages) and $package_shape.ignore == false
   }

   if ($missing_package_shapes | is-empty) {
      {std_packages: 'skipped' aur_packages: 'skipped' local_packages: 'skipped'} | print
      return
   }

   let missing_std_packages = $missing_package_shapes
   | where from == 'std'
   | each {|missing_std_package_shape| $missing_std_package_shape.name }

   let install_std_packages_status: string = do {
      if ($missing_std_packages | is-empty) {
         return 'skipped'
      }

      try {
         pacman -S ...$missing_std_packages
         'success'
      } catch {
         'failed'
      }
   }

   let missing_aur_packages = $missing_package_shapes
   | where from == 'aur'
   | each {|missing_aur_package_shape| $missing_aur_package_shape.name }

   let install_aur_packages_status: string = do {
      if ($missing_aur_packages | is-empty) {
         return 'skipped'
      }

      try {
         paru -S --aur ...$missing_aur_packages
         'success'
      } catch {
         'failed'
      }
   }

   let missing_local_package_paths = $missing_package_shapes
   | where from == 'lcl'
   | each {|missing_local_package_shape| $missing_local_package_shape.path }

   let install_local_packages_status = do {
      if ($missing_local_package_paths | is-empty) {
         return 'skipped'
      }

      try {
         paru -Bi ...$missing_local_package_paths
         'success'
      } catch {
         'failed'
      }
   }

   {
      std_packages: $install_std_packages_status
      aur_packages: $install_std_packages_status
      local_packages: $install_local_packages_status
   } | print
}

export def cleanup-package-shapes [
   package_shapes
]: nothing -> record {
   def is-package-a-dependency []: string -> bool {
      let package = $in

      let is_package_a_dependency = pactree -rl $package
      | complete
      | get stdout
      | lines
      | length
      | $in > 1

      $is_package_a_dependency
   }

   let installed_packages = pacman -Qq | lines
   let packages = $package_shapes | par-each {|package_shape| $package_shape.name }

   let unlisted_packages = $installed_packages | par-each {|installed_package|
      if ($installed_package | is-package-a-dependency) {
         return
      }

      if $installed_package in $packages {
         return
      }

      $installed_package
   }

   if ($unlisted_packages | is-empty) {
      return {
         packages: {
            status: 'skipped'
         }
      }
   }

   try {
      pacman -Rns ...$unlisted_packages
      {packages: {status: 'success'}}
   } catch {
      {packages: {status: 'failed'}}
   }
}
