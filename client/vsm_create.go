package client

import (
	"encoding/json"
	"net/url"

	"github.com/openebs/openebs/types"
	"golang.org/x/net/context"
)

// This will form the http client request to create a VSM.
func (cli *Client) VSMCreate(ctx context.Context, opts types.VSMCreateOptions) (types.Vsm, error) {
	query := url.Values{}

	query.Set("name", opts.Name)
	query.Set("ip", opts.IP)
	query.Set("interface", opts.Interface)
	query.Set("subnet", opts.Subnet)
	query.Set("router", opts.Router)
	query.Set("volume", opts.Volume)
	query.Set("storage", opts.Storage)

	var vsm types.Vsm
	resp, err := cli.post(ctx, "/vsm/create", query, nil, nil)
	if err != nil {
		return vsm, err
	}

	err = json.NewDecoder(resp.body).Decode(&vsm)
	ensureReaderClosed(resp)
	return vsm, err
}
