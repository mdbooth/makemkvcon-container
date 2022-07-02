MAKEMKV ?= 1.17.0
FFMPEG ?= 5.0.1
REGISTRY ?= quay.io/mbooth

image_targets=makemkvcon-nojava makemkvcon

.PHONY: all
all: $(image_targets)

$(image_targets):
	docker build --target $@ --build-arg MAKEMKV=$(MAKEMKV) --build-arg FFMPEG=$(FFMPEG) --squash --tag $(REGISTRY)/$@:$(MAKEMKV) .

.PHONY: push
push: $(addprefix _push_, $(image_targets))

_push_%: %
	docker push $(addprefix $(REGISTRY)/,$<):$(MAKEMKV)
