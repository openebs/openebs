# Contributing to OpenEBS

Great!! We are always on the lookout for more OpenEBS hackers. You can get started by reading this [Overview](./contribute/design/README.md)

OpenEBS is innovation in OpenSource. You are welcome to contribute in any way you can and all the help you can provide is very much appreciated. 

- Raise Issues on either the functionality or documentation
- Submit Changes to Improve Documentation 
- Submit Proposals for new Features/Enhancements 
- Submit Changes to the Source Code

There are just a few simple guidelines that you need to follow before providing your hacks. 

## Raising Issues

When Raising issues, please specify the following:
- Setup details (like hyperconverged/dedicated), orchestration engine - kubernetes, docker swarm etc,. 
- Scenario where the issue was seen to occur
- If the issue is with storage, include maya version, maya osh-status and maya omm-status.
- Errors and log messages that are thrown by the sofware


## Submit Change to Improve Documentation

Getting Documentation Right is Hard! Please raise a PR with you proposed changes. 

## Submit Proposals for New Features

There is always something more that is required, to make it easier to suit your use-cases. Feel free to join the discussion on the features or raise a new PR with your proposed change. 

## Contributing to Source Code

Provide PRs for bug fixes or enhancements.

### Sign your work

We use the Developer Certificate of Origin (DCO) as a additional safeguard
for the OpenEBS project. This is a well established and widely used
mechanism to assure contributors have confirmed their right to license
their contribution under the project's license.
Please read [developer-certificate-of-origin](../../contribute/developer-certificate-of-origin).
If you can certify it, then just add a line to every git commit message:

````
  Signed-off-by: Random J Developer <random@developer.example.org>
````

Use your real name (sorry, no pseudonyms or anonymous contributions).
If you set your `user.name` and `user.email` git configs, you can sign your
commit automatically with `git commit -s`. You can also use git [aliases](https://git-scm.com/book/tr/v2/Git-Basics-Git-Aliases)
like `git config --global alias.ci 'commit -s'`. Now you can commit with
`git ci` and the commit will be signed.
