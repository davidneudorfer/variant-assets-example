package main

import (
	"fmt"
	"os"

	"github.com/davidovich/summon/pkg/summon"
	"github.com/gobuffalo/packr/v2"
  "github.com/mumoshu/variant/pkg"
)

func main() {
	assetsDir := "assets"

	box := packr.New("Bundled Assets", assetsDir)

	summoner, err := summon.New(box)
	if err != nil {
		fmt.Fprintf(os.Stderr, "%v\n", err)
		os.Exit(1)
	}

	msg, err := summoner.Summon(
		summon.All(true),
		summon.Raw(true),
		summon.Dest(assetsDir),
	)
	if err != nil {
		fmt.Fprintf(os.Stderr, "%v\n", err)
		os.Exit(1)
	}

	fmt.Printf("summon: %s\n", msg)

	// variant-cli-output
}
