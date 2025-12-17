def is-pkg-a-dependency []: string -> bool {
   let pkg = $in

   let pkg_reverse_dependencies = pactree -rl $pkg
   | complete
   | get stdout
   | lines
   | length

   $pkg_reverse_dependencies > 1
}
