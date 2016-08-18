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

// This caters to storing OpenEBS storage state into some persistent
// medium. This `persistent medium` specific characteristics should be
// programmed here. In other words, there should not be any OpenEBS
// storage related business logic. This file should only deal with the
// technicalities of the persistent medium. In other words, this file
// should abstract the operations related to persistent medium from the
// operations related to OpenEBS storage. This can be thought of as the
// DAO layer w.r.t programming design patterns.

package daemon
