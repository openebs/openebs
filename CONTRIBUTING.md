#Contributing to OpenEBS

Great!! We are always on the lookout for more OpenEBS hackers. You can get started by reading this Overview, Setup OpenEBS on your machine and start contributing in any of the following ways:

- Raise Issues on either the functionality or documentation
- Improve Documentation 
- Submit Proposals for new Features/Enhancements 
- Submit Changes to the Source Code

There are just a few simple guidelines that you need to follow before providing your hacks. 

## Raising Issues

When Raising issues, please specify the following:
- Setup details (like hyperconverged/dedicated), orchestration engine - kubernetes, docker swarm etc,. 
- Scenario where the issue was seen to occur
- If the issue is with storage, include maya version, maya osh-status and maya omm-status.
- Errors and log messages that are thrown by the sofware


## Submit Documentation Changes

## Submit Proposals for New Features

## Contributing to Source Code

### Sign your work

We use the Developer Certificate of Origin (DCO) as a additional safeguard
for the OpenEBS project. This is a well established and widely used
mechanism to assure contributors have confirmed their right to license
their contribution under the project's license.
Please read [contribute/developer-certificate-of-origin][dcofile].
If you can certify it, then just add a line to every git commit message:

````
  Signed-off-by: Random J Developer <random@developer.example.org>
````

Use your real name (sorry, no pseudonyms or anonymous contributions).
If you set your `user.name` and `user.email` git configs, you can sign your
commit automatically with `git commit -s`. You can also use git [aliases](https://git-scm.com/book/tr/v2/Git-Basics-Git-Aliases)
like `git config --global alias.ci 'commit -s'`. Now you can commit with
`git ci` and the commit will be signed.
