package dockerlib_test

import (
	"reflect"
	"testing"

	"encoding/json"

	"github.com/influxdata/influxdata-docker/dockerlib/dockerlib"
)

func TestVersion_LessThan(t *testing.T) {
	for _, tt := range []struct {
		lhs, rhs string
		exp      bool
	}{
		{
			lhs: "1.4.2",
			rhs: "1.4",
			exp: false,
		},
		{
			lhs: "1.3.8",
			rhs: "1.4.2",
			exp: true,
		},
		{
			lhs: "1.3.8",
			rhs: "1.3.8",
			exp: false,
		},
		{
			lhs: "1.4.1",
			rhs: "1.4.2",
			exp: true,
		},
	} {
		t.Run(tt.lhs+" > "+tt.rhs, func(t *testing.T) {
			v1, err := dockerlib.NewVersion(tt.lhs)
			if err != nil {
				t.Fatalf("unexpected error: %s", err)
			}
			v2, err := dockerlib.NewVersion(tt.rhs)
			if err != nil {
				t.Fatalf("unexpected error: %s", err)
			}

			if got, exp := v1.LessThan(v2), tt.exp; got != exp {
				t.Fatalf("unexpected value: %v != %v", got, exp)
			}
		})
	}
}

func TestVersion_Segments(t *testing.T) {
	for _, tt := range []struct {
		s   string
		exp []int
	}{
		{
			s:   "1.4",
			exp: []int{1, 4},
		},
		{
			s:   "1.4.7",
			exp: []int{1, 4, 7},
		},
	} {
		t.Run(tt.s, func(t *testing.T) {
			v, err := dockerlib.NewVersion(tt.s)
			if err != nil {
				t.Fatalf("unexpected error: %s", err)
			}

			if got, exp := v.Segments(), tt.exp; !reflect.DeepEqual(got, exp) {
				t.Errorf("unexpected segments: %v != %v", got, exp)
			}
		})
	}
}

func TestVersion_String(t *testing.T) {
	for _, tt := range []struct {
		s   string
		exp string
	}{
		{
			s:   "1.4",
			exp: "1.4",
		},
		{
			s:   "v1.4",
			exp: "1.4",
		},
	} {
		t.Run(tt.s, func(t *testing.T) {
			v, err := dockerlib.NewVersion(tt.s)
			if err != nil {
				t.Fatalf("unexpected error: %s", err)
			}

			if got, exp := v.String(), tt.exp; got != exp {
				t.Errorf("unexpected string: %s != %s", got, exp)
			}
		})
	}
}

func TestVersion_UnmarshalJSON(t *testing.T) {
	s := `{"version":"v1.4.2"}`
	var data struct {
		Version *dockerlib.Version `json:"version"`
	}
	if err := json.Unmarshal([]byte(s), &data); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}

	if got, exp := data.Version.String(), "1.4.2"; got != exp {
		t.Errorf("unexpected version: %s != %s", got, exp)
	}
}
