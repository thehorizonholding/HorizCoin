package version

import "fmt"

var (
	// Version is the semantic version of the build (set via -ldflags "-X github.com/thehorizonholding/HorizCoin/internal/version.Version=<value>")
	Version = "0.0.1"
	// Commit is the git commit hash for the build (set via -ldflags)
	Commit = "dev"
	// BuiltBy is who/what produced the binary (set via -ldflags)
	BuiltBy = "local"
)

// String returns a human friendly version string.
func String() string {
	return fmt.Sprintf("v%s (%s by %s)", Version, Commit, BuiltBy)
}