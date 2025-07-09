use crate::error::{
    CommandFailed, FailedToGetChartPathMetadata, FailedTokioCommand, FailedTokioSpawn, Result,
};
use snafu::{ensure, ResultExt};
use std::{collections::HashMap, fs::Metadata, path::Path, process::Output};
use tokio::{fs, process::Command, task::JoinHandle};

/// This executes a tokio::Command and handles execution and command error.
pub async fn exec_tokio_command(
    command: String,
    args: Vec<String>,
    envs: Option<HashMap<String, String>>,
) -> Result<Output> {
    let output = Command::new(command.as_str())
        .envs(envs.clone().unwrap_or_default())
        .args(args.as_slice())
        .output()
        .await
        .context(FailedTokioCommand {
            command: command.clone(),
            args: args.clone(),
            envs: envs.clone().unwrap_or_default(),
        })?;

    ensure!(
        output.status.success(),
        CommandFailed {
            command,
            args,
            envs: envs.unwrap_or_default(),
            output: output.clone()
        }
    );

    Ok(output)
}

/// This checks a Unix-like path against a predicate function. Useful when trying to check if a path
/// is that of a file, symlink etc.
pub async fn check_path(path: impl AsRef<Path>, predicate: fn(&Metadata) -> bool) -> Result<bool> {
    fs::metadata(path.as_ref())
        .await
        .map(|ref metadata| predicate(metadata))
        .context(FailedToGetChartPathMetadata {
            path: path.as_ref().to_path_buf(),
        })
}

/// Flatten join errors and tokio task errors.
pub async fn joined_flatten<T>(handle: JoinHandle<Result<T>>) -> Result<T> {
    match handle.await.context(FailedTokioSpawn) {
        Ok(Ok(result)) => Ok(result),
        Ok(Err(err)) => Err(err),
        Err(err) => Err(err),
    }
}
