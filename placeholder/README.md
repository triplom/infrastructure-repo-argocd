# Placeholder Directories for Cross-Repository Packages

This directory contains placeholder build contexts for external packages that are built from other repositories:

- `external-app/`: Placeholder for external-app package (normally built from infrastructure-repo)
- `nginx/`: Placeholder for nginx package (normally built from k8s-web-app-php)
- `php-fpm/`: Placeholder for php-fpm package (normally built from k8s-web-app-php)

These placeholders allow the CI pipeline to demonstrate cross-repository package building when the actual source repositories are not available.

In a real scenario, these packages would be built from their respective repositories:
- external-app: https://github.com/triplom/infrastructure-repo
- nginx + php-fpm: https://github.com/triplom/k8s-web-app-php

The CI pipeline supports building all packages through workflow_dispatch with component selection.
