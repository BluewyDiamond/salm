use ../../error.nu [ ok err pkg_oks pkg_errs ]

export def main [
   pkg_shapes: table
]: nothing -> nothing {
   let installed_pkgs = pacman -Qq | lines

   let missing_pkg_shapes = $pkg_shapes | where {|pkg_shape|
      ($pkg_shape.name not-in $installed_pkgs) and $pkg_shape.ignore == false
   }

   let missing_std_pkgs = $missing_pkg_shapes
   | where from == 'std'
   | each {|missing_std_pkg_shape| $missing_std_pkg_shape.name }

   let std_pkgs_install_result: record = if ($missing_std_pkgs | is-empty) {
      ok -n $pkg_oks.SKIPPED
   } else {
      try {
         pacman -S ...$missing_std_pkgs
         ok
      } catch {|error|
         err -n $pkg_errs.CATCH -v $error
      }
   }

   let missing_aur_pkgs = $missing_pkg_shapes
   | where from == 'aur'
   | each {|missing_aur_pkg_shape| $missing_aur_pkg_shape.name }

   let aur_pkgs_install_result: record = if ($missing_aur_pkgs | is-empty) {
      ok -n $pkg_oks.SKIPPED
   } else {
      try {
         run0 -u nobody -- yay -S --repo ...$missing_aur_pkgs
         ok -n $pkg_oks.SKIPPED
      } catch {|error|
         err -n $pkg_errs.CATCH -v $error
      }
   }

   let missing_local_pkg_paths = $missing_pkg_shapes
   | where from == 'lcl'
   | each {|missing_local_pkg_shape| $missing_local_pkg_shape.path }

   let local_pkgs_install_result: record = if ($missing_local_pkg_paths | is-empty) {
      ok -n $pkg_oks.SKIPPED
   } else {
      try {
         yay -Bi ...$missing_local_pkg_paths
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
