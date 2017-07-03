# Introduction

Every project has certain philosophical conundrums, that its contributors have to grapple with. These may sound very straight-forward at onset, but you know they go deeper, when the same question keeps coming back. Following are some such conundrums and our current stand on it. 

## Should the new functionality be developed in one of the existing repositories or a new repository?

As most philosphical answers start, the answer is "it depends". But here are some general guidelines. 
- If the functionality is a straight forward extension to current functionality like adding new API to maya-server or support for new CO, use the existing repository. 
- If the functionality is experimental/poc/exploratory and you would like to seek feedback from the OpenEBS community, you can put it under openebs/elves/<sub-project>
- If the functionality has been accepted to make it into a release, but requires some work to make it part of existing repository like - openebs/openebs, openebs/jiva or openebs/maya, put it into a new repository, till it gets cooked. Typical examples are - when the functionality has to be packaged into its own container or runs as an independent service etc,. 


