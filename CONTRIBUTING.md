# Contributing to OpenEBS

Great!! We are always on the lookout for more OpenEBS hackers. You can get started by reading this [Overview](./contribute/design/README.md)

First: if you're unsure or afraid of anything, just ask or submit the issue or pull request anyways. You won't be yelled at for giving your best effort. The worst that can happen is that you'll be politely asked to change something. We appreciate any sort of contributions, and don't want a wall of rules to get in the way of that.

However, for those individuals who want a bit more guidance on the best way to contribute to the project, read on. This document will cover what we're looking for. By addressing all the points we're looking for, it raises the chances we can quickly merge or address your contributions.

That said, OpenEBS is an innovation in open-source. You are welcome to contribute in any way you can and all the help provided is very much appreciated. 

- Raise issues to request new functionality, fix documentation or for reporting bugs.
- Submit changes to improve documentation. 
- Submit proposals for new features/enhancements.
- Submit fixes for bugs reported/found. 
- Submit changes to the source code.

There are just a few simple guidelines that you need to follow before providing your hacks. 

## Raising Issues

When raising issues, please specify the following:
- Setup details (like hyperconverged/dedicated), orchestration engine - kubernetes, docker swarm etc. 
- Scenario where the issue was seen to occur (With details on how to reproduce it)
- If the issue is with storage, include maya version, maya osh-status and maya omm-status.
- Errors and log messages that are thrown by the software

## Submit Change to Improve Documentation

Getting documentation right is hard! Please raise a PR with your proposed changes. Giving details on what exactly you trying to improve in the documentation.

## Submit Proposals for New Features

There is always something more that is required, to make it easier to suit your use-cases. Feel free to join the discussion on new features or raise a PR with your proposed change. 

## Contributing to Source Code & Bug Fixes

Provide PRs for bug fixes or enhancements to the source code.

---
### Sign your work

We use the Developer Certificate of Origin (DCO) as a additional safeguard for the OpenEBS project. This is a well established and widely used mechanism to assure contributors have confirmed their right to license their contribution under the project's license. Please read [developer-certificate-of-origin](https://github.com/openebs/openebs/blob/master/contribute/developer-certificate-of-origin).

If you can certify it, then just add a line to every git commit message:

````
  Signed-off-by: Random J Developer <random@developer.example.org>
````
or use the command `git commit -s -m "commit message comes here"` to sign-off on your commits.

Use your real name (sorry, no pseudonyms or anonymous contributions). If you set your `user.name` and `user.email` git configs, you can sign your commit automatically with `git commit -s`. You can also use git [aliases](https://git-scm.com/book/tr/v2/Git-Basics-Git-Aliases) like `git config --global alias.ci 'commit -s'`. Now you can commit with `git ci` and the commit will be signed.
