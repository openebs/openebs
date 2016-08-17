package client

import (
	"encoding/json"
	"net/url"

	"github.com/openebs/openebs/types"
	"golang.org/x/net/context"
)

// Invoke the list command exposed by the server/daemon
func (cli *Client) VSMList(ctx context.Context, options types.VSMListOptions) ([]types.Vsm, error) {
	query := url.Values{}

	if options.All {
		query.Set("all", "1")
	}

	resp, err := cli.get(ctx, "/vsm/list", query, nil)
	if err != nil {
		return nil, err
	}

	var vsms []types.Vsm
	err = json.NewDecoder(resp.body).Decode(&vsms)
	ensureReaderClosed(resp)
	return vsms, err
}
