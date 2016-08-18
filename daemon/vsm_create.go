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

// This file will deal with create and create related operations w.r.t
// OpenEBS storage. Appropriate structures in this file will be used to
// invoke VSM create operations and their variants.

// NOTE - There can be multiple variations of creating a VSM.
// NOTE - A create variant is thought of as an orthogonal action
//        i.e. applying some aspect(s) over regular create operation.

// Below represents some samples of VSM creation variants:
//   e.g. - Create a VSM that allows only a single storage.
//   e.g. - Create a VSM that is suitable for hosting the storage
//          for DB applications.
//   e.g. - Create a VSM that exposes its monitoring stats.
//   e.g. - Create a VSM that by-passes certain validations.
//   e.g. - Simulate creation of a VSM without actually creating rather
//          verifying if create is feasible or not.

package daemon
