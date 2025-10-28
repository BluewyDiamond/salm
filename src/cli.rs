use clap::{Args, Parser, Subcommand};

#[derive(Parser)]
pub struct Cli {
   #[command(subcommand)]
   pub command: CliCommand,
}

#[derive(Subcommand)]
pub enum CliCommand {
   Install(Install),
   Cleanup,
   Uninstall,
   Sync,
}

#[derive(Args)]
pub struct Install {
   pub profiles: Vec<String>,
}
