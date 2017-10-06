package main

import (
	"bufio"
	"bytes"
	"container/list"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
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

type Manifest struct {
	Name          string   `json:"name"`
	BaseDir       string   `json:"-"`
	Versions      []string `json:"versions"`
	Architectures []string `json:"architectures"`
	Variants      []string `json:"variants"`
	Latest        string   `json:"-"`
}

func FindManifests() ([]*Manifest, error) {
	var manifests []*Manifest
	if err := filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		} else if info.IsDir() && info.Name() == ".git" {
			return filepath.SkipDir
		}

		// Check if there is a manifest.json in this folder.
		if info.Name() != "manifest.json" {
			return nil
		}

		// We found a manifest.json in this folder. Read and parse it into a manifest.
		in, err := ioutil.ReadFile(path)
		if err != nil {
			return err
		}

		var manifest Manifest
		if err := json.Unmarshal(in, &manifest); err != nil {
			return err
		}
		manifest.BaseDir = filepath.Dir(path)

		// Look through each of the versions to determine which is the latest.
		if len(manifest.Versions) > 0 {
			var latest *Version
			for _, versionStr := range manifest.Versions {
				v, err := NewVersion(versionStr)
				if err != nil {
					return err
				}

				if latest == nil || v.GreaterThan(latest) {
					latest = v
				}
			}
			manifest.Latest = latest.String()
		}
		manifests = append(manifests, &manifest)
		return nil
	}); err != nil {
		return nil, err
	}
	return manifests, nil
}

func (m *Manifest) UpdateImage() error {
	var headers []*Header
	for _, v := range m.Versions {
		h, err := m.updateForVersion(filepath.Join(m.BaseDir, v))
		if err != nil {
			return err
		}
		headers = append(headers, h...)
	}

	libraryFile := filepath.Join("../official-images/library", m.Name)
	f, err := os.Create(libraryFile)
	if err != nil {
		return err
	}
	defer f.Close()

	fmt.Fprintf(f, "Maintainers: %s\n\n", getDefaultMaintainer())
	for i, h := range headers {
		if i > 0 {
			f.WriteString("\n")
		}
		h.Write(f)
	}
	return nil
}

func (m *Manifest) updateForVersion(path string) ([]*Header, error) {
	// Retrieve the architectures. If none are specified, assume amd64 as the default.
	archs := m.Architectures
	if len(archs) == 0 {
		archs = []string{"amd64"}
	}

	// Iterate through each of the architectures and variants.
	// Everything should have the same version.
	var versionStr string
	for _, arch := range archs {
		// Check to see if a special directory exists for this architecture.
		// If it does not, then use the base directory.
		dir := filepath.Join(path, arch)
		if _, err := os.Stat(dir); err != nil {
			if !os.IsNotExist(err) {
				return nil, err
			}
			dir = path
		}

		if v, err := getVersion(dir); err != nil {
			return nil, err
		} else if versionStr != "" && versionStr != v {
			return nil, fmt.Errorf("mismatched versions: %s != %s", versionStr, v)
		} else if versionStr == "" {
			versionStr = v
		}
	}

	// Look through the variants too. Variants must have their own directory.
	for _, variant := range m.Variants {
		if v, err := getVersion(filepath.Join(path, variant)); err != nil {
			return nil, err
		} else if versionStr != "" && versionStr != v {
			return nil, fmt.Errorf("mismatched versions: %s != %s", versionStr, v)
		} else if versionStr == "" {
			versionStr = v
		}
	}

	// The last section of the path should be a prefix of the version.
	if !strings.HasPrefix(versionStr, filepath.Base(path)) {
		return nil, fmt.Errorf("manifest version is not a prefix of the dockerfile version: %v.HasPrefix(%v)", versionStr, filepath.Base(path))
	}

	// Parse the version inside of the dockerfile so we can use it.
	v, err := NewVersion(versionStr)
	if err != nil {
		return nil, fmt.Errorf("unable to parse version %v: %s", versionStr, err)
	}

	// Store the relevant information in a Header.
	header := &Header{}
	for i := 2; i <= len(v.Segments()); i++ {
		segments := v.Segments()
		parts := make([]string, i)
		for j, s := range segments[:i] {
			parts[j] = strconv.Itoa(s)
		}
		header.Add("Tags", strings.Join(parts, "."))
	}
	if m.Latest == filepath.Base(path) {
		header.Add("Tags", "latest")
	}

	// Add each of the architectures.
	for _, arch := range m.Architectures {
		header.Add("Architectures", arch)
	}

	// Store the current Git Repo, Git Commit, and the Directory.
	header.Set("GitRepo", remoteRepo)

	rev, err := latestRev(path)
	if err != nil {
		return nil, err
	}
	header.Set("GitCommit", rev)
	header.Set("Directory", path)

	// Iterate through each of the architectures and add any overrides.
	for _, arch := range m.Architectures {
		dir := filepath.Join(path, arch)
		if _, err := os.Stat(dir); err != nil {
			if !os.IsNotExist(err) {
				return nil, err
			}
			continue
		}
		header.Add(fmt.Sprintf("%s-Directory", arch), dir)
	}

	// Add this header as the first.
	headers := make([]*Header, 0, len(m.Versions)+1)
	headers = append(headers, header)

	// Run through each variant doing the same thing.
	for _, variant := range m.Variants {
		header := &Header{}
		for i := 2; i <= len(v.Segments()); i++ {
			segments := v.Segments()
			parts := make([]string, i)
			for j, s := range segments[:i] {
				parts[j] = strconv.Itoa(s)
			}
			header.Add("Tags", strings.Join(parts, ".")+"-"+variant)
		}
		if m.Latest == filepath.Base(path) {
			header.Add("Tags", variant)
		}
		header.Set("GitRepo", remoteRepo)
		header.Set("GitCommit", rev)
		header.Set("Directory", filepath.Join(path, variant))
		headers = append(headers, header)
	}
	return headers, nil
}

type keyValuePair struct {
	key    string
	values []string
}

type Header struct {
	values *list.List
	index  map[string]*list.Element
}

func (h *Header) Add(key, value string) {
	e, ok := h.index[key]
	if !ok {
		h.Set(key, value)
		return
	}

	kv := e.Value.(*keyValuePair)
	kv.values = append(kv.values, value)
}

func (h *Header) Set(key, value string) {
	if h.index == nil {
		h.index = make(map[string]*list.Element)
	}
	if h.values == nil {
		h.values = list.New()
	}
	values := make([]string, 1)
	values[0] = value
	h.index[key] = h.values.PushBack(&keyValuePair{
		key:    key,
		values: values,
	})
}

func (h *Header) Write(w io.Writer) error {
	for front := h.values.Front(); front != nil; front = front.Next() {
		kv := front.Value.(*keyValuePair)
		if _, err := fmt.Fprintf(w, "%s: %s\n", kv.key, strings.Join(kv.values, ", ")); err != nil {
			return err
		}
	}
	return nil
}

type Version struct {
	segments []int
}

func NewVersion(s string) (*Version, error) {
	if strings.HasPrefix(s, "v") {
		s = s[1:]
	}
	parts := strings.Split(s, ".")
	segments := make([]int, len(parts))
	for i, p := range parts {
		v, err := strconv.Atoi(p)
		if err != nil {
			return nil, fmt.Errorf("malformed version: %s", s)
		}
		segments[i] = v
	}
	return &Version{segments: segments}, nil
}

func (v *Version) GreaterThan(other *Version) bool {
	for i, s := range v.segments {
		if i >= len(other.segments) {
			return true
		}
		if a, b := s, other.segments[i]; a != b {
			return a > b
		}
	}
	return false
}

func (v *Version) Segments() []int {
	return v.segments
}

func (v *Version) String() string {
	var buf bytes.Buffer
	for i, s := range v.segments {
		if i > 0 {
			buf.WriteString(".")
		}
		buf.WriteString(strconv.Itoa(s))
	}
	return buf.String()
}

func realMain() int {
	noUpdate := flag.Bool("n", false, "do not update the repository")
	flag.Parse()

	// Update the official-images repository to the latest version of upstream.
	if !*noUpdate {
		if err := fetchUpstream(); err != nil {
			fmt.Fprintf(os.Stderr, "error: %s\n", err)
			return 1
		}
	}

	// Locate all of the manifests within this repository.
	manifests, err := FindManifests()
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %s\n", err)
		return 1
	}

	for _, m := range manifests {
		if err := m.UpdateImage(); err != nil {
			fmt.Fprintf(os.Stderr, "error: %s\n", err)
			return 1
		}
	}
	return 0
}

func main() {
	os.Exit(realMain())
}
