use ../../error.nu [ ok err unit_oks unit_errs ]
use ./enable.nu enable-units
use ./cleanup.nu cleanup-unit-shape

export def do-unit-shapes [
   unit_shapes: table
]: nothing -> nothing {
   $unit_shapes | each {|unit_shape|
      enable-units $unit_shape.user ...$unit_shape.enable
   }
}

export def cleanup-unit-shapes [
   unit_shapes: table
]: nothing -> nothing {
   $unit_shapes | each {|unit_shape|
      cleanup-unit-shape $unit_shape.user ...$unit_shape.enable
   }
}
