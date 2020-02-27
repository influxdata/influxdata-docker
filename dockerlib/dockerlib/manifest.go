package dockerlib

import (
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

type ImageManifest struct {
	Name          string     `json:"name"`
	BaseDir       string     `json:"-"`
	Maintainers   []string   `json:"maintainers"`
	Versions      []*Version `json:"versions"`
	Architectures []string   `json:"architectures"`
	Variants      []*Variant `json:"variants"`
	Latest        string     `json:"-"`
}

type Variant struct {
	Name          string     `json:"name"`
	Versions      []*Version `json:"versions"`
	Architectures []string   `json:"architectures"`
	Latest        string     `json:"-"`
}

func FindImageManifests() ([]*ImageManifest, error) {
	var manifests []*ImageManifest
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
		manifest, err := ReadImageManifest(path)
		if err != nil {
			return err
		}
		manifests = append(manifests, manifest)
		return nil
	}); err != nil {
		return nil, err
	}
	return manifests, nil
}

func ReadImageManifest(fpath string) (*ImageManifest, error) {
	in, err := ioutil.ReadFile(fpath)
	if err != nil {
		return nil, err
	}

	var manifest ImageManifest
	if err := json.Unmarshal(in, &manifest); err != nil {
		return nil, err
	}
	manifest.BaseDir = filepath.Dir(fpath)

	// Look through each of the versions to determine which is the latest.
	if len(manifest.Versions) > 0 {
		manifest.Latest = Versions(manifest.Versions).Latest().String()
	}

	// Propagate the image values to the variants and determine the base directory
	// and the latest version.
	for i, variant := range manifest.Variants {
		if len(variant.Versions) == 0 {
			manifest.Variants[i].Versions = manifest.Versions
			manifest.Variants[i].Latest = manifest.Latest
		} else {
			manifest.Variants[i].Latest = Versions(variant.Versions).Latest().String()
		}
	}
	return &manifest, nil
}

func (m *ImageManifest) Write(w io.Writer, header *Header) error {
	// Output the initial header passed in to write.
	if header != nil {
		header.Write(w)
	}

	// Determine all of the versions.
	for _, v := range m.Versions {
		dir := filepath.Join(m.BaseDir, v.String())

		header := &Header{}
		version, err := DockerfileVersion(dir)
		if err != nil {
			return err
		}
		for i := 2; i <= len(version.Segments()); i++ {
			segments := version.Segments()
			parts := make([]string, i)
			for j, s := range segments[:i] {
				parts[j] = strconv.Itoa(s)
			}
			header.Add("Tags", strings.Join(parts, "."))
		}
		if m.Latest == v.String() {
			header.Add("Tags", "latest")
		}
		for _, arch := range m.Architectures {
			header.Add("Architectures", arch)
		}
		header.Add("Directory", dir)

		fmt.Fprintln(w)
		if err := header.Write(w); err != nil {
			return err
		}

		for _, variant := range m.Variants {
			// Check if this variant is included in the list of versions.
			found := false
			for _, vv := range variant.Versions {
				if v.String() == vv.String() {
					found = true
					break
				}
			}

			// Skip this variant if the version isn't found in the variant.
			if !found {
				continue
			}

			header := &Header{}
			version, err := DockerfileVersion(dir)
			if err != nil {
				return err
			}
			name := strings.Replace(variant.Name, "/", "-", -1)
			for i := 2; i <= len(version.Segments()); i++ {
				segments := version.Segments()
				parts := make([]string, i)
				for j, s := range segments[:i] {
					parts[j] = strconv.Itoa(s)
				}
				header.Add("Tags", strings.Join(parts, ".")+"-"+name)
			}
			if variant.Latest == v.String() {
				header.Add("Tags", name)
			}
			for _, arch := range variant.Architectures {
				header.Add("Architectures", arch)
			}
			header.Add("Directory", filepath.Join(dir, variant.Name))
			//header.Add("Tags", variant.Name)
			fmt.Fprintln(w)
			if err := header.Write(w); err != nil {
				return err
			}
		}
	}

	return nil
}
