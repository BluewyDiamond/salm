// the state we left it at after installing
// useful for cleanup
struct State {
   installed_packages: Vec<String>,
   installed_file_paths: Vec<String>,
}
