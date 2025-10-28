use clap::Parser;

pub mod cli;
pub mod effect;
pub mod error;
pub mod prelude;

use crate::cli::{Cli, CliCommand};
use crate::prelude::Result;

fn main() -> Result<()> {
   let cli = Cli::parse();

   match cli.command {
      CliCommand::Install(install) => Ok(()),
      CliCommand::Cleanup => Ok(()),
      CliCommand::Uninstall => Ok(()),
      CliCommand::Sync => Ok(()),
   }
}
