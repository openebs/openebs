# Release Process

OpenEBS follows a monthly release cadence. The process is as follows:

The scope of the release is determined by:
- contributor availability, 
- pending items listed in the [roadmap](./ROADMAP.md) and 
- the [issues filed by the community](https://github.com/search?q=is%3Aissue+is%3Aopen+label%3Aproject%2Fcommunity+org%3Aopenebs&type=Issues). 

1. The release scope is published and tracked using [GitHub Projects](https://github.com/orgs/openebs/projects). To maintain monthly release cadence, the project tracker is setup with indicative milestones leading up to freezing the feature development in the 3rd week, the remaining days are used to run e2e and fix any issues found by e2e or community. 
1. At the start of the release cycle, one of the contributors takes on the role of release manager and works with the OpenEBS Maintainers to co-ordinate the release activities.  
1. Contributors sync-up over [community calls and slack](./community/) to close on the release tasks. Release manager runs the community calls for a given release. In the community call, the risks are identified and mitigated by seeking additional help or by pushing the task to next release.
1. The various release management tasks are explained in the [release process document](./contribute/process/release-management.md).
1. OpenEBS release is made via GitHub. Once all the components are released, [Change Summary](https://github.com/openebs/openebs/wiki) is updated and [openebs/openebs](https://github.com/openebs/openebs/releases) repo is tagged with the release. 
1. OpenEBS release is announced on [all Community reach out channels](./community/).
1. The release tracker GitHub project is closed
