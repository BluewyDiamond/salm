use ./do-units/mask-units.nu
use ./do-units/enable-units.nu

export def main [unit_shapes: table]: nothing -> nothing {
   $unit_shapes | each {|unit_shape|
      enable-units $unit_shape.user ...$unit_shape.enable
   }
}
