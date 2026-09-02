use super::{api::ApiClient, node::target_nodes, CliArgs, Error, GetTaskArg, GetTasksArg};
use plugin::resources::utils::{print_table, CreateRows, GetHeaderRow};
use types::{RawfileTaskObject, RawfileTaskRecord};

use lazy_static::lazy_static;
use prettytable::{row, Row};

pub(crate) mod types;

lazy_static! {
    pub(crate) static ref RAWFILE_TASK_HEADER: Row =
        row!["ID", "NODE", "TASK", "STATE", "RETRIES", "ARGS",];
}

/// Implementation for tasks cmd.
pub(crate) async fn tasks(
    cli_args: &CliArgs,
    tasks_arg: &GetTasksArg,
    api: &ApiClient,
) -> Result<(), Error> {
    let nodes = target_nodes(api, tasks_arg.node.as_deref()).await?;
    let mut tasks = Vec::new();
    for node in &nodes {
        // The api-server reports nothing for a node it cannot reach.
        let Some(node_tasks) = api.tasks(&node.name).await? else {
            eprintln!(
                "Couldnt get tasks of localpv-rawfile node: {} (node is {})",
                node.name,
                if node.online { "online" } else { "offline" }
            );
            continue;
        };
        tasks.extend(
            node_tasks
                .iter()
                .map(|(id, task)| RawfileTaskObject::from((id.as_str(), node.name.as_str(), task))),
        );
    }
    print_table(&cli_args.output, RawfileTaskRecord::new(tasks));
    Ok(())
}

/// Implementation for task cmd.
pub(crate) async fn task(
    cli_args: &CliArgs,
    task_arg: &GetTaskArg,
    api: &ApiClient,
) -> Result<(), Error> {
    let task = match &task_arg.node {
        // The node is known, so the task can be fetched directly.
        Some(node) => api
            .task(node, &task_arg.task_id)
            .await?
            .map(|task| RawfileTaskObject::from((task_arg.task_id.as_str(), node.as_str(), &task))),
        // Otherwise the task has to be looked for on each node.
        None => {
            let nodes = target_nodes(api, None).await?;
            let mut found = None;
            for node in &nodes {
                if let Some(task) = api.task(&node.name, &task_arg.task_id).await? {
                    found = Some(RawfileTaskObject::from((
                        task_arg.task_id.as_str(),
                        node.name.as_str(),
                        &task,
                    )));
                    break;
                }
            }
            found
        }
    };
    let task = task.ok_or_else(|| Error::NotFound {
        resource: "Task".to_string(),
        name: task_arg.task_id.clone(),
    })?;
    print_table(&cli_args.output, RawfileTaskRecord::new(vec![task]));
    Ok(())
}

impl GetHeaderRow for RawfileTaskRecord {
    fn get_header_row(&self) -> Row {
        (*RAWFILE_TASK_HEADER).clone()
    }
}

impl CreateRows for RawfileTaskRecord {
    fn create_rows(&self) -> Vec<Row> {
        self.tasks()
            .iter()
            .map(|task| {
                row![
                    task.id(),
                    task.node(),
                    task.task(),
                    task.state(),
                    task.retries(),
                    task.args()
                ]
            })
            .collect()
    }
}
