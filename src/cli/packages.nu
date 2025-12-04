use ../error.nu [ ok err pkg_oks pkg_errs ]

export def install-pkg-shapes [
   pkg_shapes: table
]: nothing -> nothing {
   let installed_pkgs = pacman -Qq | lines

   let missing_pkg_shapes = $pkg_shapes | where {|pkg_shape|
      ($pkg_shape.name not-in $installed_pkgs) and $pkg_shape.ignore == false
   }

   if ($missing_pkg_shapes | is-empty) {
      {
         std_pkgs: (ok -n $pkg_oks.SKIPPED | to nuon)
         aur_pkgs: (ok -n $pkg_oks.SKIPPED | to nuon)
         local_pkgs: (ok -n $pkg_oks.SKIPPED | to nuon)
      } | print

      return
   }

   let missing_std_pkgs = $missing_pkg_shapes
   | where from == 'std'
   | each {|missing_std_pkg_shape| $missing_std_pkg_shape.name }

   let std_pkgs_install_result: record = do {
      if ($missing_std_pkgs | is-empty) {
         return (ok -n $pkg_oks.SKIPPED)
      }

      try {
         pacman -S ...$missing_std_pkgs
         ok -n $pkg_oks.SKIPPED
      } catch {|error|
         err -n $pkg_errs.CATCH -v $error
      }
   }

   let missing_aur_pkgs = $missing_pkg_shapes
   | where from == 'aur'
   | each {|missing_aur_pkg_shape| $missing_aur_pkg_shape.name }

   let aur_pkgs_install_result: record = do {
      if ($missing_aur_pkgs | is-empty) {
         return (ok -n $pkg_oks.SKIPPED)
      }

      try {
         paru -S --aur ...$missing_aur_pkgs
         ok -n $pkg_oks.SKIPPED
      } catch {|error|
         err -n $pkg_errs.CATCH -v $error
      }
   }

   let missing_local_pkg_paths = $missing_pkg_shapes
   | where from == 'lcl'
   | each {|missing_local_pkg_shape| $missing_local_pkg_shape.path }

   let local_pkgs_install_result: record = do {
      if ($missing_local_pkg_paths | is-empty) {
         return (ok -n $pkg_oks.SKIPPED)
      }

      try {
         paru -Bi ...$missing_local_pkg_paths
         ok -n $pkg_oks.SKIPPED
      } catch {|error|
         err -n $pkg_errs.CATCH -v $error
      }
   }

   let status_for_user = {
      std_pkgs: ($std_pkgs_install_result | to nuon)
      aur_pkgs: ($aur_pkgs_install_result | to nuon)
      local_pkgs: ($local_pkgs_install_result | to nuon)
   }

   $status_for_user | print
}

export def cleanup-pkg-shapes [
   pkg_shapes
]: nothing -> record {
   let installed_pkgs = pacman -Qq | lines
   let pkgs = $pkg_shapes | par-each {|pkg_shape| $pkg_shape.name }

   let unwanted_pkgs = $installed_pkgs | par-each {|installed_pkg|
      if ($installed_pkg | is-pkg-a-dependency) {
         return
      }

      if $installed_pkg in $pkgs {
         return
      }

      $installed_pkg
   }

   if ($unwanted_pkgs | is-empty) {
      return {
         pkgs: {
            status: (ok -n $pkg_oks.SKIPPED)
         }
      }
   }

   try {
      pacman -Rns ...$unwanted_pkgs

      {
         pkgs: {
            status: (ok | to nuon)
         }
      }
   } catch {|error|
      {
         pkgs: {
            status: (err -n $pkg_errs.CATCH -v $error | to nuon)
         }
      }
   }
}

def is-pkg-a-dependency []: string -> bool {
   let pkg = $in

   let pkg_reverse_dependencies = pactree -rl $pkg
   | complete
   | get stdout
   | lines
   | length

   $pkg_reverse_dependencies > 1
}
