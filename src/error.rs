#[derive(thiserror::Error, Debug)]
pub enum Error {
   #[error("Generic Error")]
   GenericError,
}
