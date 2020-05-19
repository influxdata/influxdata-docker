ifndef IMAGE
$(error IMAGE is not set)
endif

ifndef VARIANT
$(error VARIANT is not set)
endif

ifndef VERSION
$(error VERSION is not set)
endif

# This works for `nightly` too, as it doesn't match semver format and won't be modified
MAJORMINORVERSION=$(shell echo $(VERSION) | perl -pe  's/^(\d+)\.(\d+)\.(\d+)$$/$$1.$$2/g')

ifeq ($(VARIANT), debian)
CONTEXT=./$(IMAGE)/$(MAJORMINORVERSION)
else
CONTEXT=./$(IMAGE)/$(MAJORMINORVERSION)/$(VARIANT)
endif

build-image:
	@docker image build --build-arg VERSION=$(VERSION) --no-cache -f $(CONTEXT)/Dockerfile $(CONTEXT)
