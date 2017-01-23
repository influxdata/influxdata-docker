package main

import (
	"bufio"
	"bytes"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"

	version "github.com/hashicorp/go-version"
	"github.com/spf13/pflag"
)

const remoteRepo = "git://github.com/influxdata/influxdata-docker"

func currentRev() (string, error) {
	var buf bytes.Buffer
	cmd := exec.Command("git", "rev-parse", "HEAD")
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

func findDockerfiles() ([]string, error) {
	var dirs []string
	if err := filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		} else if info.IsDir() && (info.Name() == "nightly" || info.Name() == ".git") {
			return filepath.SkipDir
		}

		// Check if there is a Dockerfile in this folder.
		if info.Name() != "Dockerfile" {
			return nil
		}

		// We found a Dockerfile.
		dirs = append(dirs, filepath.Dir(path))
		return nil
	}); err != nil {
		return nil, err
	}
	return dirs, nil
}

type Library struct {
	Maintainer string
	Revs       map[string]string
}

func ReadLibrary(r io.Reader) (*Library, error) {
	library := &Library{
		Revs: make(map[string]string),
	}

	scanner := bufio.NewScanner(r)
OUTER:
	for {
		var dir, commit string
		for scanner.Scan() {
			line := scanner.Text()
			if line == "" {
				if dir != "" && commit != "" {
					library.Revs[dir] = commit
				}
				continue OUTER
			}

			parts := strings.SplitN(line, ":", 2)
			if len(parts) != 2 {
				continue
			}
			key, value := parts[0], strings.TrimSpace(parts[1])

			switch key {
			case "Maintainers":
				library.Maintainer = value
			case "GitCommit":
				commit = value
			case "Directory":
				dir = value
			}
		}
		if dir != "" && commit != "" {
			library.Revs[dir] = commit
		}
		return library, nil
	}
}

func getDefaultMaintainer() string {
	return "Jonathan A. Sternberg <jonathan@influxdb.com> (@jsternberg)"
}

// getVersion reads the Dockerfile, finds the version, and outputs it.
func getVersion(dir string) (string, error) {
	f, err := os.Open(filepath.Join(dir, "Dockerfile"))
	if err != nil {
		return "", err
	}
	defer f.Close()

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		line := scanner.Text()
		if !strings.HasPrefix(line, "ENV ") {
			continue
		}

		parts := strings.Split(line, " ")
		if len(parts) != 3 || !strings.HasSuffix(parts[1], "_VERSION") {
			continue
		}
		return parts[2], nil
	}
	return "", nil
}

func realMain() int {
	noUpdate := pflag.BoolP("no-update", "n", false, "do not update the repository")
	pflag.Parse()

	// Update the official-images repository to the latest version of upstream.
	if !*noUpdate {
		if err := fetchUpstream(); err != nil {
			fmt.Fprintf(os.Stderr, "error: %s\n", err)
			return 1
		}
	}

	// Find which Dockerfile's exist in the repository.
	dirs, err := findDockerfiles()
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %s\n", err)
		return 1
	}

	// Load the image names.
	images := make(map[string][]string)
	for _, dir := range dirs {
		parts := strings.SplitN(dir, string(os.PathSeparator), 2)
		if len(parts) > 1 {
			name := parts[0]
			images[name] = append(images[name], parts[1])
		}
	}

	// Load the library files to find the existing revisions.
	revs := make(map[string]string)
	maintainers := make(map[string]string)
	for name := range images {
		f, err := os.Open(filepath.Join("../official-images/library", name))
		if err != nil {
			continue
		}

		library, err := ReadLibrary(f)
		if err != nil {
			f.Close()
			fmt.Fprintf(os.Stderr, "error reading library file: %s\n", err)
			return 1
		}
		f.Close()

		maintainers[name] = library.Maintainer
		for k, v := range library.Revs {
			revs[k] = v
		}
	}

	// Find the current revision.
	rev, err := currentRev()
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %s\n", err)
		return 1
	}

	// Print out each of the directories and the currently known revision.
	for _, dir := range dirs {
		r, ok := revs[dir]
		if !ok {
			// Set the revision for this directory to the current revision.
			revs[dir] = rev
			continue
		}

		// If the revision is different from the current revision, check if we
		// need to update it by running a diff between the current revision and
		// this one.
		if r == rev {
			continue
		}

		cmd := exec.Command("git", "diff", "--quiet", fmt.Sprintf("%s..%s", r, rev), "--", dir)
		if err := cmd.Run(); err != nil {
			if _, ok := err.(*exec.ExitError); !ok {
				fmt.Fprintf(os.Stderr, "error: %s\n", err)
				return 1
			}

			// An error indicates there is something different. This may catch
			// a change in a subfolder, but I don't really care since these
			// will commonly be changed at the same time.
			revs[dir] = rev
		}
	}

	// Iterate over each of the images so we can rewrite the files.
	for name, dirs := range images {
		sort.Strings(dirs)

		versions := make(map[string]string, len(dirs))
		for _, dir := range dirs {
			v, err := getVersion(filepath.Join(name, dir))
			if err != nil {
				continue
			}
			versions[dir] = v
		}

		var (
			prefix string
			latest *version.Version
		)
		for dir, v := range versions {
			if strings.Contains(v, "~rc") || strings.Contains(v, "-rc") {
				continue
			}
			ver, err := version.NewVersion(v)
			if err != nil {
				continue
			}

			if latest == nil || ver.GreaterThan(latest) {
				parts := strings.SplitN(dir, string(os.PathSeparator), 2)
				prefix = parts[0]
				latest = ver
			}
		}

		var buf bytes.Buffer
		m := maintainers[name]
		if m == "" {
			m = getDefaultMaintainer()
		}
		fmt.Fprintf(&buf, "Maintainers: %s\n", m)

		for _, subdir := range dirs {
			dir := filepath.Join(name, subdir)
			v := versions[subdir]

			var tags []string
			if strings.Contains(v, "~rc") || strings.Contains(v, "-rc") {
				tag := strings.Replace(strings.Replace(v, "~", "-", -1), string(os.PathSeparator), "-", -1)
				if strings.HasSuffix(subdir, "alpine") {
					tag += "-alpine"
				}
				tags = append(tags, tag)
			} else {
				tags = append(tags, strings.Replace(subdir, string(os.PathSeparator), "-", -1))
				parts := strings.SplitN(subdir, string(os.PathSeparator), 2)
				if len(parts) > 1 {
					tags = append(tags, fmt.Sprintf("%s-%s", v, strings.Replace(parts[1], string(os.PathSeparator), "-", -1)))
				} else {
					tags = append(tags, v)
				}

				if strings.HasPrefix(subdir, prefix) {
					if strings.HasSuffix(subdir, "alpine") {
						tags = append(tags, "alpine")
					} else {
						tags = append(tags, "latest")
					}
				}
			}

			fmt.Fprintf(&buf, "\nTags: %s\n", strings.Join(tags, ", "))
			fmt.Fprintf(&buf, "GitRepo: %s\n", remoteRepo)
			fmt.Fprintf(&buf, "GitCommit: %s\n", revs[dir])
			fmt.Fprintf(&buf, "Directory: %s\n", dir)
		}

		libraryFile := filepath.Join("../official-images/library", name)
		cur, err := ioutil.ReadFile(libraryFile)
		if err == nil && bytes.Equal(buf.Bytes(), cur) {
			continue
		}

		if err := ioutil.WriteFile(libraryFile, buf.Bytes(), 0666); err != nil {
			fmt.Fprintf(os.Stderr, "error: write file: %s\n", err)
			return 1
		}
		fmt.Printf("Wrote %s\n", libraryFile)
	}
	return 0
}

func main() {
	os.Exit(realMain())
}
