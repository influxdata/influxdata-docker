package main

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

const remoteRepo = "git://github.com/influxdata/influxdata-docker"

func latestRev(path string) (string, error) {
	var buf bytes.Buffer
	cmd := exec.Command("git", "rev-list", "-1", "--first-parent", "HEAD", "--", path)
	cmd.Stdout = &buf
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		return "", err
	}
	return strings.TrimSpace(buf.String()), nil
}

func fetchUpstream() error {
	cmd := exec.Command("/bin/sh", "-c", "git fetch upstream; git merge --ff-only upstream/master")
	cmd.Dir = "../official-images"
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		return err
	}
	return nil
}

func getDefaultMaintainers() []string {
	return []string{"Jonathan A. Sternberg <jonathan@influxdata.com> (@jsternberg)"}
}

func main() {
	if err := RootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %s\n", err)
		os.Exit(1)
	}
}
