use crate::cli_utils::localpv::rawfile::{api::Task, NO_CONTENT};

use serde::{Deserialize, Serialize};

/// Struct to construct cli result from.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub(crate) struct RawfileTaskObject {
    /// Id of the task.
    id: String,
    /// Node the task is queued on.
    node: String,
    /// Name of the task.
    task: String,
    /// State of the task.
    state: String,
    /// Number of times the task has been retried.
    retries: u32,
    /// Positional arguments of the task.
    args: String,
    /// Keyword arguments of the task.
    kwargs: String,
}

/// Getter implementations for RawfileTaskObject.
impl RawfileTaskObject {
    /// Returns id of the task.
    pub(crate) fn id(&self) -> &String {
        &self.id
    }

    /// Returns node the task is queued on.
    pub(crate) fn node(&self) -> &String {
        &self.node
    }

    /// Returns name of the task.
    pub(crate) fn task(&self) -> &String {
        &self.task
    }

    /// Returns state of the task.
    pub(crate) fn state(&self) -> &String {
        &self.state
    }

    /// Returns number of times the task has been retried.
    pub(crate) fn retries(&self) -> u32 {
        self.retries
    }

    /// Returns positional arguments of the task.
    pub(crate) fn args(&self) -> &String {
        &self.args
    }
}

/// Takes a task as reported by the api-server with its id and node, Returns RawfileTaskObject.
impl From<(&str, &str, &Task)> for RawfileTaskObject {
    fn from((id, node, task): (&str, &str, &Task)) -> Self {
        Self {
            id: id.to_string(),
            node: node.to_string(),
            task: task.task.clone(),
            state: task.state.clone(),
            retries: task.retry_count,
            args: join_or_none(task.args.iter().flatten().map(String::clone), " "),
            kwargs: join_or_none(
                task.kwargs.iter().flatten().map(|(key, value)| {
                    // A string value is unquoted, anything else keeps its json form.
                    let value = value
                        .as_str()
                        .map(str::to_string)
                        .unwrap_or_else(|| value.to_string());
                    format!("{key}={value}")
                }),
                ",",
            ),
        }
    }
}

/// Joins the arguments for a table cell, or reports that there are none.
fn join_or_none(args: impl Iterator<Item = String>, separator: &str) -> String {
    let args = args.collect::<Vec<_>>();
    if args.is_empty() {
        return NO_CONTENT.to_string();
    }
    args.join(separator)
}

/// A record containing a collection of localpv-rawfile tasks.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub(crate) struct RawfileTaskRecord {
    /// A vector of rawfile tasks.
    tasks: Vec<RawfileTaskObject>,
}

impl RawfileTaskRecord {
    /// Constructs RawfileTaskRecord object.
    pub(crate) fn new(tasks: Vec<RawfileTaskObject>) -> Self {
        Self { tasks }
    }

    /// Returns task list present in the RawfileTaskRecord.
    pub(crate) fn tasks(&self) -> &Vec<RawfileTaskObject> {
        &self.tasks
    }
}
