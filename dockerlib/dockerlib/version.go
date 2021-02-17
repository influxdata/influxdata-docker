package dockerlib

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"reflect"
	"strconv"
	"strings"
)

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

func (v *Version) LessThan(other *Version) bool {
	for i, s := range v.segments {
		if i >= len(other.segments) {
			return false
		}
		if a, b := s, other.segments[i]; a != b {
			return a < b
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

func (v *Version) UnmarshalJSON(data []byte) error {
	var s string
	if err := json.Unmarshal(data, &s); err != nil {
		return err
	}

	version, err := NewVersion(s)
	if err != nil {
		return err
	}
	*v = *version
	return nil
}

type Versions []*Version

func (a Versions) Len() int           { return len(a) }
func (a Versions) Less(i, j int) bool { return a[i].LessThan(a[j]) }
func (a Versions) Swap(i, j int)      { a[i], a[j] = a[j], a[i] }

// Contains returns true if this array contains the version.
func (a Versions) Contains(other *Version) bool {
	for _, v := range a {
		if reflect.DeepEqual(v.segments, other.segments) {
			return true
		}
	}
	return false
}

// Latest returns the latest version from an array of version strings.
func (a Versions) Latest() *Version {
	var latest *Version
	for _, v := range a {
		if latest == nil || latest.LessThan(v) {
			latest = v
		}
	}
	return latest
}

// DockerfileVersion retrieves the version from a Dockerfile.
func DockerfileVersion(dir string) (*Version, error) {
	f, err := os.Open(filepath.Join(dir, "Dockerfile"))
	if err != nil {
		return nil, err
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

		// Split the version on a dash.
		sections := strings.Split(parts[2], "-")
		return NewVersion(sections[0])
	}
	return nil, nil
}
