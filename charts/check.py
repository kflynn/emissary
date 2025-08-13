#!/usr/bin/env python

import sys
import yaml

resources = yaml.safe_load_all(sys.stdin)

for resource in resources:
    resource_kind = resource['kind']
    resource_name = resource['metadata']['name']

    if resource_kind == 'CustomResourceDefinition':
        crd_versions = resource['spec']['versions']

        versions = []

        for version in crd_versions:
            name = version['name']
            stored = "Y" if version['storage'] else "N"

            versions.append(f"{name}: {stored}")

        print(f"{resource_name}: {', '.join(versions)}")
    else:
        print(f"{resource_name}: {resource_kind}")

