package client

import (
	"encoding/json"
	"net/url"

	"github.com/openebs/openebs/types"
	"golang.org/x/net/context"
)

// ContainerList returns the list of containers in the docker host.
func (cli *Client) VSMList(ctx context.Context, options types.VSMListOptions) ([]types.Vsm, error) {
	query := url.Values{}

	if options.All {
		query.Set("all", "1")
	}

	resp, err := cli.get(ctx, "/vsm/lsjson", query, nil)
	if err != nil {
		return nil, err
	}

	var vsms []types.Vsm
	err = json.NewDecoder(resp.body).Decode(&vsms)
	ensureReaderClosed(resp)
	return vsms, err
}
