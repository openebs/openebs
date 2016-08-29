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

// This will have the structures & behaviors related to common
// storage operations.
package daemon

import "github.com/openebs/openebs/types"

// This is responsible for Open EBS specific operation.
// A single method interface will help us in adhering to
// 'Single Responsibility Principle' i.e. SRP.
type Executor interface {
	Exec() (*types.Response, error)
}

// A functional type that allows to implement Executor interface
// as long as the func signature matches.
type ExecutorFn func() (*types.Response, error)

// As long as ExecutorFn implements the Executor interface,
// the logic of Exec method will be as simple as execution
// of self.
func (f ExecutorFn) Exec() (*types.Response, error) {
	return f()
}

// This is responsible for Audit specific operations.
// Various implementations of Audit logic will be possible
// via this common contract.
type Auditor interface {
	Audit() (*types.Response, error)
}

// A functional type that allows to implement Auditor interface
// as long as the func signature matches.
type AuditorFn func() (*types.Response, error)

// As long as AuditorFn implements the Auditor interface,
// the logic of Audit method will be as simple as execution
// of self.
func (f AuditorFn) Audit() (*types.Response, error) {
	return f()
}

// A log based auditor. In other words a concrete/specific auditor
// implementation.
func LogAuditor() Auditor {
	return AuditorFn(func() (*types.Response, error) {
		return &types.Response{Val: "Action was audited in logs."}, nil
	})
}

// A functional type that will be used to add behavior
// to exec operations in a de-coupled manner via the usage
// of decorator pattern. In other words it will accept an
// Executor and return another variant of same Executor.
type ExecDecoratorFn func(Executor) Executor

// This composes the provided Executor with Audit related logic and returns
// a modified Executor.
func AuditDecorator(a Auditor) ExecDecoratorFn {
	return func(e Executor) Executor {
		return ExecutorFn(func() (*types.Response, error) {
			// auditing the storage operation
			var ar, sr *types.Response
			var err error

			if ar, err = a.Audit(); err != nil {
				return ar, err
			}

			// executing the storage operation
			sr, err = e.Exec()

			if sr != nil {
				sr.Merge(ar)
			} else {
				sr = ar
			}

			return sr, err
		})
	}
}

// An utility function that composes an Executor with variadic
// number of decorators. In other words, this decorates the
// Executor & results in a new variant of Executor.
// NOTE - This does not result into actual execution of business
// logic, but results into creation of nested functional wrappers.
func Decorate(e Executor, ds ...ExecDecoratorFn) (decorated Executor) {
	decorated = e

	for _, d := range ds {
		decorated = d(decorated)
	}

	return
}
