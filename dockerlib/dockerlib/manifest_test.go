package dockerlib

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
)

var exampleManifest = `{
  "name": "influxdb",
  "maintainers": ["Test Maintainer"],
  "major-versions": [
    {
      "name": "1.x",
      "versions": ["1.7", "1.8"],
      "architectures": ["amd64", "arm32v7", "arm64v8"],
      "variants": [
        { "name": "alpine" },
        { "name": "data" },
        { "name": "data/alpine" },
        { "name": "meta" },
        { "name": "meta/alpine" }
      ]
    },
    {
      "name": "2.x",
      "versions": ["2.0"],
      "architectures": ["amd64", "arm64v8"],
      "variants": [
        { "name": "alpine" }
      ]
    }
  ]
}`

var manifestVersions = map[string]string{
	"influxdb/1.7": "1.7.10",
	"influxdb/1.7/alpine": "1.7.10",
	"influxdb/1.7/meta": "1.7.10",
	"influxdb/1.7/meta/alpine": "1.7.10",
	"influxdb/1.7/data": "1.7.10",
	"influxdb/1.7/data/alpine": "1.7.10",
	"influxdb/1.8": "1.8.3",
	"influxdb/1.8/alpine": "1.8.3",
	"influxdb/1.8/meta": "1.8.3",
	"influxdb/1.8/meta/alpine": "1.8.3",
	"influxdb/1.8/data": "1.8.3",
	"influxdb/1.8/data/alpine": "1.8.3",
	"influxdb/2.0": "2.0.4",
	"influxdb/2.0/alpine": "2.0.4",
}

func lookupVersion(dir string) (*Version, error) {
	v, ok := manifestVersions[dir]
	if !ok {
		return nil, fmt.Errorf("unknown directory: %q", dir)
	}

	return NewVersion(v)
}

var expectedOutput = `Maintainers: Test Maintainer

Tags: 1.7, 1.7.10
Architectures: amd64, arm32v7, arm64v8
Directory: influxdb/1.7

Tags: 1.7-alpine, 1.7.10-alpine
Directory: influxdb/1.7/alpine

Tags: 1.7-data, 1.7.10-data
Directory: influxdb/1.7/data

Tags: 1.7-data-alpine, 1.7.10-data-alpine
Directory: influxdb/1.7/data/alpine

Tags: 1.7-meta, 1.7.10-meta
Directory: influxdb/1.7/meta

Tags: 1.7-meta-alpine, 1.7.10-meta-alpine
Directory: influxdb/1.7/meta/alpine

Tags: 1.8, 1.8.3
Architectures: amd64, arm32v7, arm64v8
Directory: influxdb/1.8

Tags: 1.8-alpine, 1.8.3-alpine
Directory: influxdb/1.8/alpine

Tags: 1.8-data, 1.8.3-data
Directory: influxdb/1.8/data

Tags: 1.8-data-alpine, 1.8.3-data-alpine
Directory: influxdb/1.8/data/alpine

Tags: 1.8-meta, 1.8.3-meta
Directory: influxdb/1.8/meta

Tags: 1.8-meta-alpine, 1.8.3-meta-alpine
Directory: influxdb/1.8/meta/alpine

Tags: 2.0, 2.0.4, latest
Architectures: amd64, arm64v8
Directory: influxdb/2.0

Tags: 2.0-alpine, 2.0.4-alpine, alpine
Directory: influxdb/2.0/alpine
`

func TestManifest_e2e(t *testing.T) {
	tmp, err := ioutil.TempDir("", "")
	assert.NoError(t, err)
	defer os.RemoveAll(tmp)

	manifestFile := filepath.Join(tmp, "manifest.json")
	assert.NoError(t, ioutil.WriteFile(manifestFile, []byte(exampleManifest), os.ModePerm))

	manifest, err := ReadImageManifest(manifestFile)
	assert.NoError(t, err)

	manifest.BaseDir = "influxdb"
	header := &Header{}
	for _, maintainer := range manifest.Maintainers {
		header.Add("Maintainers", maintainer)
	}

	var buf bytes.Buffer
	assert.NoError(t, manifest.Write(&buf, header, lookupVersion))
	assert.Equal(t, expectedOutput, buf.String())
}
