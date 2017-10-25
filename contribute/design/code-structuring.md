# Code Structuring FAQ

Every project has certain philosophical conundrums, that its contributors have to grapple with. These may sound very straightforward at onset, but you know they go deeper when the same question keeps coming back. Following are some such conundrums and our current stand on it. 

## Should the new functionality to be developed in one of the existing repositories or a new repository?

As most philosophical answers start, the answer is "it depends". But here are some general guidelines. 
- If the functionality is a straightforward extension of current functionality, like adding new API to [mayaserver](https://github.com/openebs/mayaserver) or support for new CO, use the existing repository. 
- If the functionality is experimental/poc/exploratory and you would like to seek feedback from the OpenEBS community, you can put it under [openebs/elves](https://github.com/openebs/elves).
- If the functionality has been accepted to make it into a release, but requires some work to make it part of existing repository like - [openebs/openebs](https://github.com/openebs/openebs), [openebs/jiva](https://github.com/openebs/jiva) or [openebs/maya](https://github.com/openebs/maya), put it into a new repository, till it gets cooked. Typical examples are - when the functionality has to be packaged into its own container or runs as an independent service etc,. 

## Is there a convention followed for the Go project structure?

Follow the principles listed by [Package Oriented Design](https://www.goinggo.net/2017/02/package-oriented-design.html)

There are several different ways in which go projects are structured out there - for instance from [kubernetes](https://github.com/kubernetes/kubernetes) (using a single repository for multiple binaries) to [consul](https://github.com/hashicorp/consul) (with single binary - that acts as both cli, client and server), and [docker](https://github.com/docker) (with somewhere in between). With these choices, it also becomes difficult to pick a path forward, especially with the language that is strongly opinionated. After having tried a few ways, the current stance stands as follows:

- **pkg** will contain the utility packages (home grown or wrappers around other libraries - like log helpes, network helpers etc.,)
- **types** that are defined as high level structs without dependency on any other types. These can be used for interacting with other systems (outside of this repository) or between apps in this repository.
- **internal** will contain the first class citizens of the product - or what were called the main objects on which CRUDs are performed. 
- **cmd** will contain the binaries (main package) or multiple applications, which will delegate the heavy lifting to their corresponding apps.

The **pkg** and **types** are intentionally kept at the top level, in case they need to be moved their own repositories in the future. 

The order of the listing also roughly determines the dependencies or the import rules. For example, packages in **cmd** can import anything from above packages but not vice-versa.
