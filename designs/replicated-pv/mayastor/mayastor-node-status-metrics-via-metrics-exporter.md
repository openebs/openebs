---
oep-number: TBC
title: mayastor-node-status-metrics-via-metrics-exporter
authors:
  - "@IyanekiB"
  - "@pjgranieri"
owners:
  - "@tiagocastroferreira"
  - "@Abhinandan-Purkait"
editor: TBD
creation-date: 2025-11-18
last-updated: 2025-11-18
status: provisional
replaces:
superseded-by:
---

# Mayastor Node Status Metrics via Metrics Exporter

## Table of Contents

* [Summary](#summary)
* [Motivation](#motivation)
  * [Goals](#goals)
  * [Non-Goals](#non-goals)
* [Proposal](#proposal)
  * [Implementation Details](#implementation-details)
  * [Risks and Mitigations](#risks-and-mitigations)
* [Graduation Criteria](#graduation-criteria)
* [Implementation History](#implementation-history)
* [Drawbacks](#drawbacks)
* [Alternatives](#alternatives)
* [Infrastructure Needed](#infrastructure-needed)
* [Testing](#testing)

## Summary

This proposal establishes the metrics-exporter as the single surface for Mayastor node-status metrics by extending it with a lightweight REST client.
Instead of generating metrics directly in the control-plane REST service, the exporter periodically queries control-plane endpoints, derives node states, and exposes Prometheus-compatible gauges for online, cordoned, and draining states.

## Motivation

Surfacing metrics directly from the REST service risks duplicating business logic, requires additional auth/scrape plumbing, and can produce divergent metric formats.
Centralizing node state reporting inside the metrics-exporter aligns with how other Mayastor operational metrics are exposed and creates a reusable pattern for REST-backed observations.

This work follows the lessons learned in [PR #1035](https://github.com/openebs/mayastor-control-plane/pull/1035), which introduced node-status metrics at the REST layer.
Moving this logic into the exporter yields a more maintainable, observable, and testable pipeline.

### Goals

* Add node-status gauges to the existing metrics-exporter binary.
* Introduce a minimal REST client for retrieving authoritative control-plane node state.
* Preserve compatibility with existing Prometheus/Grafana pipelines.
* Establish a pattern for REST-sourced metrics that does not leak business logic into observability tooling.

### Non-Goals

* Changing control-plane scheduling or node lifecycle logic.
* Altering existing Prometheus endpoints or naming conventions.
* Introducing new protocols for metrics delivery.

## Proposal

Extend the current metrics-exporter so it can:

1. Periodically query the control-plane `/v0/nodes` REST endpoint (and future node-related endpoints as needed).
2. Parse node metadata, in-memory cache it, and derive three booleans per node: online, cordoned, and draining.
3. Expose the derived values through the existing `/metrics` endpoint as Prometheus gauges:
   * `mayastor_node_online` (0/1)
   * `mayastor_node_cordoned` (0/1)
   * `mayastor_node_draining` (0/1)
4. Keep the exporter deployment / scrape configuration unchanged so Prometheus and Grafana continue to rely on the same endpoints.

### Implementation Details

* The REST client will reuse the existing control-plane authentication model (service account credentials inside the exporter pod) to avoid new secrets.
* Polling cadence will match other exporter loops (default 15s) and include jitter plus circuit-breaking so that REST failures do not block metric updates.
* Metrics are updated atomically per scrape cycle to avoid mixed-state results within a scrape window.
* The exporter remains stateless; no new storage or CRDs are introduced.
* Architectural flow:
  1. Control-plane stays the authoritative source of node state.
  2. Metrics-exporter polls REST, refreshes its cached state, and updates gauges.
  3. Prometheus scrapes the exporter.
  4. Grafana dashboards consume the same series without modification.

### Risks and Mitigations

* **REST unavailability:** When the control-plane REST service is unreachable the exporter could emit stale data. Mitigation: surface `mayastor_node_status_scrape_error` counters and keep the last known state with timestamps so operators can alert on scrape gaps.
* **Increased exporter CPU usage:** Polling REST plus metric translation adds work. Mitigation: implementation optimizes payload parsing, reuses connections, and supports configurable intervals to bound overhead.
* **Auth drift between components:** Exporter credentials might not match REST expectations. Mitigation: reuse existing service account RBAC that already grants metrics-exporter read-only access to REST.

## Graduation Criteria

* Metrics-exporter publishes node state gauges that match REST data within a single polling interval.
* Prometheus rules and Grafana dashboards consume the new metrics without configuration changes.
* Automated tests (unit + mocked integration) exercise success, failure, and transient REST states.
* At least one end-to-end validation demonstrates scraping accuracy across exporter upgrades.

## Implementation History

* 2025-11-18: Draft created as *provisional* for community review.

## Drawbacks

* Slightly increases the responsibilities of the metrics-exporter, requiring ongoing maintenance of the REST client and associated error handling.

## Alternatives

* **Keep logic in REST:** Continue emitting metrics directly from the REST service, but this fragments observability surfaces and duplicates metrics plumbing.
* **Sidecar translator:** Deploy an additional REST-to-metrics component, but that increases operational cost and still requires the exporter path for other metrics.

## Infrastructure Needed

No new infrastructure is required beyond updating the existing metrics-exporter container image.

## Testing

* Unit tests covering REST polling logic and node-to-metric mapping.
* Mocked tests verifying rapid node state transitions (online <-> cordoned <-> draining).
* Local Prometheus scrape validation to ensure metric names and labels follow conventions.
* Optional Grafana dashboard verification to confirm existing panels render correctly.
