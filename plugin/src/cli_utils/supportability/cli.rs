use crate::cli_utils::localpv::lvm::supportability::lvm_dump;
use crate::cli_utils::localpv::zfs::supportability::zfs_dump;
use crate::cli_utils::supportability::{DumpArgs, Resource, SupportArgs};
use plugin::ExecuteOperation;
use supportability::collect::common::{DumpConfig, OutputFormat};
use supportability::collect::error::Error;
use supportability::collect::system_dump::SystemDumper;
use supportability::collect::utils::log;
use supportability::operations::SystemDumpArgs;

impl DumpArgs {
    pub(crate) async fn execute(&self) -> Result<(), anyhow::Error> {
        self.resource.execute(&self.args).await
    }
}

#[async_trait::async_trait(?Send)]
impl ExecuteOperation for Resource {
    type Args = SupportArgs;
    type Error = anyhow::Error;

    async fn execute(&self, cli_args: &Self::Args) -> Result<(), Self::Error> {
        execute_resource_dump(cli_args.clone(), self.clone())
            .await
            .map_err(|e| anyhow::anyhow!("{:?}", e))
    }
}

// Holds prefix of archive file name
pub(crate) const ARCHIVE_PREFIX: &str = "openebs";

async fn execute_resource_dump(cli_args: SupportArgs, resource: Resource) -> Result<(), Error> {
    let config = DumpConfig::new(
        cli_args.output_directory_path().to_string(),
        cli_args.namespace().to_string(),
        cli_args.loki_endpoint().cloned(),
        cli_args.etcd_endpoint().cloned(),
        *cli_args.since(),
        cli_args.kubeconfig().cloned(),
        *cli_args.timeout(),
        OutputFormat::Tar,
        cli_args.tenant_id().to_string(),
        cli_args.logging_label_selectors().to_string(),
    );
    match resource {
        Resource::System(args) => {
            let mut system_dumper =
                SystemDumper::get_or_panic_system_dumper(config, ARCHIVE_PREFIX).await;

            let mut errors = Vec::new();

            if let Err(error) = openebs_system_dump(&mut system_dumper, args).await {
                errors.push(error);
            }

            if let Err(e) = system_dumper.fill_archive_and_delete_tmp() {
                log(format!("Failed to copy content to archive, error: {e:?}"));
                errors.push(e);
            }

            if !errors.is_empty() {
                log("Failed to dump system state".to_string());
                return Err(Error::MultipleErrors(errors));
            }
            println!("Completed collection of dump !!");
        }
    }
    Ok(())
}

pub async fn openebs_system_dump(
    system_dumper: &mut SystemDumper,
    args: SystemDumpArgs,
) -> Result<(), Error> {
    let mut errors = Vec::new();
    if !args.disable_log_collection() {
        if let Err(e) = system_dumper.collect_and_dump_loki_logs().await {
            errors.push(e);
        }
    }
    if let Err(e) = system_dumper.dump_common_k8s_resources().await {
        errors.push(e);
    }

    if let Err(e) = system_dumper.dump_mayastor().await {
        errors.push(e);
    }

    let k8s_client = system_dumper.k8s_client();
    let dir_path = system_dumper.dir_path();

    if let Err(e) = zfs_dump(k8s_client, &dir_path).await {
        errors.push(e);
    }

    if let Err(e) = lvm_dump(k8s_client, &dir_path).await {
        errors.push(e);
    }

    if !errors.is_empty() {
        log("Failed to dump system state".to_string());
        return Err(Error::MultipleErrors(errors));
    }
    Ok(())
}
