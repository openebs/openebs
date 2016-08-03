### What is the significance of router ?

- Routing implies mapping the http requests to specific handler logic.
- Router specific mappings are defined in this package.

### Important Notes:

- router.go defines the interface(s) related to http requests from client to server.
- local.go refers to local routing.
- Each folder inside the router package refers to an ```entity``` within openebs server.
  - This folder consolidates all routing related mapping w.r.t that particular entity.

