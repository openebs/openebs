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

// This file will deal with list and list related operations w.r.t
// OpenEBS VSM. Appropriate structures in this file will be used to
// invoke VSM list operations and their variants.

// NOTE - There can be multiple variations of listing a VSM.
// NOTE - A list variant is thought of as an orthogonal action
//        i.e. applying some aspect(s) over regular list operation.

// Below represents some samples of VSM list variants:
//   e.g. - Limit the listing of VSMs to certain number only.
//   e.g. - Limit the listing of VSMs to errorneous ones only.
//   e.g. - Limit the listing of VSMs to highly active ones only.
//   e.g. - Limit the listing of VSMs to inactive ones only.

package daemon
