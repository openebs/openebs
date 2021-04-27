# Community Support Process

## Monthly Community Tracker

OpenEBS uses GitHub Projects to track the slack support tasks. A new tracker is created for each month. The monthly community trackers can be found [here](https://github.com/orgs/openebs/projects/).

The trackers are used to ensure that feedback from the community is available in a format that can be consumed by contributors and maintainers.

### The process for updating the OpenEBS Community Tracker is as follows:

The OpenEBS maintainers, contributors, and users provide community support via [GitHub issues](https://github.com/openebs/openebs/issues) or through the Kubernetes Slack workspace. For details on joining the slack, please see the instructions [here](https://github.com/openebs/openebs/tree/master/community#contact).

One or more of the OpenEBS contributors may also take up the additional responsibility of curating the tickets coming through the community support channels and update the Community Tracker.

1. **Add new tickets**: Read through the [slack threads](https://kubernetes.slack.com/messages/openebs) created during the duration of the month,  **E.g.** For the [2021 - April Community Tracker](https://github.com/orgs/openebs/projects/31) project, we'll look at posts created during the month of April, 2021. Add new queries as cards in the `New` section. For queries which already have their own GitHub issue, add the issue card into the `New` section. Add a link to the slack thread in the card to add context to the ticket.

2. **Update existing tickets**: Issues which have been engaged need to move out of the `New` section. If the slack conversation is active and progressing, move the card to the `In progress` section. If the conversation needs feedback from the user to progress, move the card to the `Waiting on user feedback` section.

3. **Reach resolution**: Issues which reach resolution should ideally have a line or two describing how it was resolved. Issues may reach resolution in one of 3 ways (4 sections)...
	- *Resolved* -- Move cards to this section when user's query has been resolved, and no code or documentation change could be recommended.

	- *Needs quick update to code / Needs quick update to docs* -- Move cards to this section if the resolution demands a change in OpenEBS code/documentation. All cards in these sections have to be linked to a GitHub issue. The cards in this section should reach the `Done` section when their respective GitHub issues close.

	- *Pushed into roadmap* -- Move cards to this section if changes suggested in the ticket are going to be implemented at a later date, but not immediately. Discussing with the repo maintainers is a good way to find out if a ticket should be a part of the roadmap.





