pub struct Config {
   package_config: Option<PackageConfig>,
   unit_config: Option<UnitConfig>,
}

pub struct PackageConfig {
   package_specs: Vec<LocalPackage>,
   profiles: Vec<String>,
}

pub struct PackageSpec {
   standard: Option<Vec<String>>,
   aur: Option<Vec<String>>,
   local: Option<Vec<LocalPackage>>,
}

pub struct LocalPackage {
   name: String,
   path: String,
}

pub struct UnitConfig {
   unit_specs: Vec<UnitSpec>,
}

pub struct UnitSpec {
   username: String,
   enable: Vec<String>,
   mask: Vec<String>,
   profiles: Vec<String>,
}

pub struct FileConfig {
   file_specs: Vec<FileSpec>,
}

pub struct FileSpec {
   source: String,
   target: String,
   action: String,
   chmod: String,
   owner: String,
   group: String,
   profiles: Vec<String>,
}
