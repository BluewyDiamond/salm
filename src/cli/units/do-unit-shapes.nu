use ./do-unit-shapes/mask-units.nu
use ./do-unit-shapes/enable-units.nu

export def main [unit_shapes: table]: nothing -> nothing {
   $unit_shapes | each {|unit_shape|
      enable-units $unit_shape.user ...$unit_shape.enable
   }
}
