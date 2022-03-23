#!/usr/bin/env bash
# Expects developer requirements to be installed (for Tutor, PyYAML, and tutor-contrib-coursegraph).
# Expects caddy to be installed.
# Warning: This script changes some Tutor configuration values! Never run it on a production
# system. If you run it locally, back up your Tutor config.yml; after running the script,
# restore your config.yml and re-render your environment with `tutor config save`.
set -xeuo pipefail

FAKE_PASSWORD=password1234
FAKE_DOCKER_REGISTRY=fakeregistry.example.com/
FAKE_VERSION=9.9.9
FAKE_HOST=fakecoursegraph.example.edu

EXPECTED_PASSWORD_CONFIG='"password": "password1234"'
EXPECTED_DOCKER_IMAGE="fakeregistry.example.com/neo4j:9.9.9"
EXPECTED_CADDYFILE_BOLT_HOST_MATCHER='bolt.fakecoursegraph.example.edu{$default_site_port} {'


get_local_docker_image() {
	cat "$(tutor config printroot)/env/local/docker-compose.yml" | \
		python -c "import sys,yaml; print(yaml.safe_load(sys.stdin)['services']['coursegraph']['image'])" | \
		tr -d '\n'  # drop trailing newline
}


tutor plugins enable coursegraph

tutor config save \
	--set DOCKER_REGISTRY="$FAKE_DOCKER_REGISTRY" \
	--set COURSEGRAPH_NEO4J_VERSION="$FAKE_VERSION" \
	--set COURSEGRAPH_NEO4J_PASSWORD="$FAKE_PASSWORD" \
	--set COURSEGRAPH_NEO4J_HOST="$FAKE_HOST" \

set +x
echo
echo

echo "Checking if CMS production settings file parses & contains our custom fake password..."
cms_prod_settings="$(tutor config printroot)/env/apps/openedx/settings/cms/production.py"
echo   "  (File path: $cms_prod_settings)"
echo
python -m py_compile "$cms_prod_settings" | sed 's/^/  /'
echo "  File is valid Python."
echo
grep "$EXPECTED_PASSWORD_CONFIG" "$cms_prod_settings" 1>/dev/null || \
	(echo "  File is missing expected line: $EXPECTED_PASSWORD_CONFIG" && exit 1)
echo "  File contains expected line: '$EXPECTED_PASSWORD_CONFIG'"
echo
echo


echo "Checking if local docker-compose.yml parses & uses our custom fake docker image..."
local_docker_compose="$(tutor config printroot)/env/local/docker-compose.yml"
echo   "  (File path: $local_docker_compose)"
echo
docker_image=$(\
	cat "$local_docker_compose" \
	| python -c "import sys,yaml; print(yaml.safe_load(sys.stdin)['services']['coursegraph']['image'])" \
	| tr -d '\n'  # drop trailing newline
)
[[ "$docker_image" = "$EXPECTED_DOCKER_IMAGE" ]] || \
	(echo "  Expected file to define coursegraph image as: $EXPECTED_DOCKER_IMAGE" && \
	 echo "  Actual image value was: '$docker_image'." && \
	 exit 1)
echo "  File is valid YAML and defines expected Docker image:  '$EXPECTED_DOCKER_IMAGE'"
echo
echo

echo "Checking if the Caddyfile (for k8s deployment) parses & contains our custom fake Bolt hostname..."
caddyfile="$(tutor config printroot)/env/apps/caddy/Caddyfile"
echo   "  (File path: $caddyfile)"
echo
caddy validate --config "$caddyfile" 2>/dev/null | sed 's/^/  /'
echo
grep "$EXPECTED_CADDYFILE_BOLT_HOST_MATCHER" "$caddyfile" 1>/dev/null  || \
	(echo "  Missing expected line: $EXPECTED_CADDYFILE_BOLT_HOST_MATCHER" && \
	 echo "  from Caddyfile at: $caddyfile" && \
	 exit 1)
echo "  File contains expected line: '$EXPECTED_CADDYFILE_BOLT_HOST_MATCHER'"
echo
echo
