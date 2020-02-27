package main

import (
	"os"

	"path/filepath"

	"fmt"

	"github.com/influxdata/influxdata-docker/dockerlib/dockerlib"
	"github.com/spf13/cobra"
)

var RootCmd = &cobra.Command{
	Use:   "dockerlib",
	Short: "Manage docker official images",
}

var UpdateCmd = &cobra.Command{
	Use:   "update",
	Short: "Update the official-images repository",
	Run: func(cmd *cobra.Command, args []string) {
		if err := Update(); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %s\n", err)
			os.Exit(1)
		}
	},
}

func Update() error {
	// Locate all of the manifests within this repository.
	manifests, err := dockerlib.FindImageManifests()
	if err != nil {
		return err
	}

	for _, m := range manifests {
		if len(m.Maintainers) == 0 {
			m.Maintainers = getDefaultMaintainers()
		}
		header := dockerlib.Header{}
		for _, maintainer := range m.Maintainers {
			header.Add("Maintainers", maintainer)
		}
		header.Add("GitRepo", remoteRepo)

		rev, err := latestRev(m.BaseDir)
		if err != nil {
			return err
		}
		header.Add("GitCommit", rev)

		if err := func() error {
			f, err := os.Create(filepath.Join("../official-images/library", m.Name))
			if err != nil {
				return err
			}
			defer f.Close()

			if err := m.Write(f, &header); err != nil {
				return err
			}
			return f.Close()
		}(); err != nil {
			return err
		}
	}
	return nil
}

func init() {
	RootCmd.AddCommand(UpdateCmd)
}
