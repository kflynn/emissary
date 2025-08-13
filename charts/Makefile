all: chart

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

emissary-crds-chart-$(VERSION).tgz: version-check emissary-crds-chart
	rm -rf emissary-crds-chart-$(VERSION)
	cp -pr emissary-crds-chart emissary-crds-chart-$(VERSION)
	sed -e "s/%VERSION%/$(VERSION)/" \
		< emissary-crds-chart-$(VERSION)/Chart.yaml > emissary-crds-chart-$(VERSION)/Chart-fixed.yaml
	mv emissary-crds-chart-$(VERSION)/Chart-fixed.yaml emissary-crds-chart-$(VERSION)/Chart.yaml
	helm package ./emissary-crds-chart-$(VERSION)

push-chart: version-check helm-registry-check emissary-crds-chart-$(VERSION).tgz
	if [ -n "$(HELM_REGISTRY)" ]; then \
		helm push emissary-crds-chart-$(VERSION).tgz $(HELM_REGISTRY); \
	else \
		echo "HELM_REGISTRY not set, not pushing"; \
	fi

# This is just an alias
chart: emissary-crds-chart-$(VERSION).tgz

clean:
	rm -rf emissary-crds-chart-*
