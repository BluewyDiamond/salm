use ../../error.nu [ ok err pkg_oks pkg_errs ]



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
            status: (err -n $pkg_errs.CATCH -v $error.msg | to nuon)
         }
      }
   }
}


