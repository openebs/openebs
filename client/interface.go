package client

import (
	"github.com/openebs/openebs/types"
	"golang.org/x/net/context"
)

// CommonAPIClient is the common methods between stable and experimental versions of APIClient.
type CommonAPIClient interface {
	SystemAPIClient
	VSMAPIClient
	ClientVersion() string
	ServerVersion(ctx context.Context) (types.Version, error)
}

// SystemAPIClient defines API client methods for the system
type SystemAPIClient interface {
	Info(ctx context.Context) (types.Info, error)
}

// VSMAPIClient defines API client methods for the system
type VSMAPIClient interface {
	VSMList(ctx context.Context, options types.VSMListOptions) ([]types.Vsm, error)
	VSMCreate(ctx context.Context, options types.VSMCreateOptions) (types.Vsm, error)
}
