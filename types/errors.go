package types

import "errors"

// ErrorResponse is the response body of API errors.
type ErrorResponse struct {
	Message string `json:"message"`
}

// Declare all the errors possible
var (
	// When an invalid option is provided along with any request
	InvalidOptionType = errors.New("Invalid option type provided.")
	// There can be cases where the option can be valid but may not
	// be supported currently or in some version
	UnsupportedOptionType = errors.New("Option type not supported.")
)
