// Copyright 2016 CloudByte, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// This file will deal with update and update related operations w.r.t
// OpenEBS storage. Appropriate structures in this file will be used to
// invoke VSM update operations and their variants.

// NOTE - There can be multiple variations of updating a VSM.
// NOTE - A update variant is thought of as an orthogonal action
//        i.e. applying some aspect(s) over regular update operation.

// Below represents some samples of VSM update variants:
//   e.g. - Update a VSM.
//   e.g. - Update a VSM with profiling turned on.
//   e.g. - Update a VSM forcibly.
//   e.g. - Update a VSM and return its stats before and after
//          the operation.
//   e.g. - Simulate updating a VSM without actually updating rather
//          verifying if update is feasible without any side-effects.

package daemon
