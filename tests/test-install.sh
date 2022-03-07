#!/usr/bin/env bash
# Expects developer requirements to be installed (for Tutor, PyYAML, and tutor-contrib-coursegraph)
# Warning: This script changes some Tutor configuration values!
set -xeuo pipefail

FAKE_DOCKER_REGISTRY=fakeregistry.example.com/
FAKE_VERSION=9.9.9
FAKE_BOLT_PORT=7999
FAKE_HOST=fakecoursegraph.example.edu

EXPECTED_DOCKER_IMAGE="fakeregistry.example.com/neo4j:9.9.9"
EXPECTED_BOLT_PORT_MAPPING="7687:7999"
EXPECTED_HOST_CONFIG='"host": "fakecoursegraph.example.edu"'


get_local_docker_image() {
	cat "$(tutor config printroot)/env/local/docker-compose.yml" | \
		python -c "import sys,yaml; print(yaml.safe_load(sys.stdin)['services']['coursegraph']['image'])" | \
		tr -d '\n'  # drop trailing newline
}

get_dev_bolt_port_mapping() {
	cat "$(tutor config printroot)/env/dev/docker-compose.yml" | \
		python -c "import sys,yaml; print(yaml.safe_load(sys.stdin)['services']['coursegraph']['ports'][1])" | \
		tr -d '\n'  # drop trailing newline
}


# Enable plugin.
tutor plugins enable coursegraph

# Set fake config values and render config to root.
tutor config save \
	--set DOCKER_REGISTRY="$FAKE_DOCKER_REGISTRY" \
	--set COURSEGRAPH_NEO4J_VERSION="$FAKE_VERSION" \
	--set COURSEGRAPH_NEO4J_HOST="$FAKE_HOST" \
	--set COURSEGRAPH_NEO4J_BOLT_PORT="$FAKE_BOLT_PORT"

set +x

echo "Checking if local docker-compose.yml parses & contains custom fake docker image..."
docker_image=$(get_local_docker_image)
[[ "$docker_image" = "$EXPECTED_DOCKER_IMAGE" ]] || \
	(echo "Expected coursegraph image to be: $EXPECTED_DOCKER_IMAGE" && \
	 echo "Actual value was: '$docker_image'." && \
	 exit 1)

echo "Checking if dev docker-compose.yml parses & contains custom fake port mapping..."
dev_bolt_port_mapping=$(get_dev_bolt_port_mapping)
[[ "$dev_bolt_port_mapping" = "$EXPECTED_BOLT_PORT_MAPPING" ]] || \
	(echo "Expected bolt port mapping to be: $EXPECTED_BOLT_PORT_MAPPING" && \
	 echo "Actual value was: $dev_bolt_port_mapping" && \
	 exit 1)

# See if an app settings file was rendered correctly.
echo "Checking if CMS development.py parses & contains custom fake host name..."
cms_dev_settings="$(tutor config printroot)/env/apps/openedx/settings/cms/development.py"
python -m py_compile "$cms_dev_settings"
cat "$cms_dev_settings" | grep "$EXPECTED_HOST_CONFIG" 1>/dev/null || \
	(echo "Missing expected line: $EXPECTED_HOST_CONFIG" && \
	 echo "from CMS dev settings file at: $cms_dev_settings" && \
	 exit 1)
