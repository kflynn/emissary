IMAGE_REPO ?= ghcr.io/emissary-ingress/emissary
CHART_DIR ?= $(OSS_HOME)/charts
BUILD_CHART ?= $(OSS_HOME)/tools/src/build-chart

CRDS_CHART = $(CHART_DIR)/emissary-crds-chart-$(VERSION).tgz
EMISSARY_CHART = $(CHART_DIR)/emissary-ingress-$(VERSION).tgz

charts: emissary-crds-chart emissary-ingress

# These are just aliases
emissary-crds-chart: $(CRDS_CHART)
emissary-ingress: $(EMISSARY_CHART)

version-check:
	@if [ -z "$(VERSION)" ]; then \
		echo "VERSION must be set (e.g. VERSION=1.0.0-alpha.3)" >&2 ;\
		exit 1; \
	fi
.PHONY: version-check

helm-registry-check:
	@if [ -z "$(HELM_REGISTRY)" ]; then \
		echo "HELM_REGISTRY must be set (e.g. HELM_REGISTRY=oci://docker.io/dwflynn)" >&2 ;\
		exit 1; \
	fi
.PHONY: helm-registry-check

# These are the CRDs that we want to package into Helm templates. Perhaps, later,
# this should be auto-generated -- but not now, when we want to be sure we have
# control over exactly what goes in.
CRD_FILES= \
	authservices.yaml \
	consulresolvers.yaml \
	devportals.yaml \
	hosts.yaml \
	kubernetesendpointresolvers.yaml \
	kubernetesserviceresolvers.yaml \
	listeners.yaml \
	logservices.yaml \
	mappings.yaml \
	modules.yaml \
	ratelimitservices.yaml \
	tcpmappings.yaml \
	tlscontexts.yaml \
	tracingservices.yaml

helmify-crds: $(OSS_HOME)/.venv $(OSS_HOME)/_generate.tmp/crds
	rm -f $(patsubst %,$(CHART_DIR)/emissary-crds/templates/%,$(CRD_FILES))
	uv run python $(CHART_DIR)/helmify-crds.py \
		--output $(CHART_DIR)/emissary-crds/templates \
		$(patsubst %,$(OSS_HOME)/_generate.tmp/crds/getambassador.io_%,$(CRD_FILES))

$(CRDS_CHART): version-check $(CHART_DIR)/emissary-crds helmify-crds
	( cd $(CHART_DIR) && bash $(BUILD_CHART) emissary-crds $(VERSION) $(IMAGE_REPO) $(CHART_DIR) )
	ls -l $(CRDS_CHART)

$(EMISSARY_CHART): version-check $(CHART_DIR)/emissary-ingress
	( cd $(CHART_DIR) && bash $(BUILD_CHART) emissary-ingress $(VERSION) $(IMAGE_REPO) $(CHART_DIR) )
	ls -l $(EMISSARY_CHART)

push-chart: version-check helm-registry-check
	if [ -n "$(HELM_REGISTRY)" ]; then \
		helm push $(CRDS_CHART) $(HELM_REGISTRY); \
		helm push $(EMISSARY_CHART) $(HELM_REGISTRY); \
	else \
		echo "HELM_REGISTRY not set, not pushing"; \
	fi

clean:
	rm -rf $(CHART_DIR)/*.tgz
