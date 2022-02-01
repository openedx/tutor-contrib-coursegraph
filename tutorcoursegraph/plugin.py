from glob import glob
from typing import List
import os
import pkg_resources

import click

from .__about__ import __version__

templates = pkg_resources.resource_filename(
    "tutorcoursegraph", "templates"
)

config = {
    "add": {
        "NEO4J_PASSWORD": "{{ 20|random_string }}",
    },
    "defaults": {
        "VERSION": __version__,
        "NEO4J_VERSION": "3.5.28",
        "NEO4J_DOCKER_IMAGE": "{{ DOCKER_REGISTRY }}neo4j:{{ COURSEGRAPH_NEO4J_VERSION }}",
        "NEO4J_HOST": "coursegraph.{{ LMS_HOST }}",
        "NEO4J_PORT": 7687,
        "NEO4J_USER": "neo4j",
        "NEO4J_SECURE": True,
        "NEO4J_PROTOCOL": "bolt",
    },
}

hooks = {
    "remote-image": {"coursegraph": "{{ COURSEGRAPH_NEO4J_DOCKER_IMAGE }}"},
    "init": ["cms"],
}


def patches():
    all_patches = {}
    patches_dir = pkg_resources.resource_filename(
        "tutorcoursegraph", "patches"
    )
    for path in glob(os.path.join(patches_dir, "*")):
        with open(path) as patch_file:
            name = os.path.basename(path)
            content = patch_file.read()
            all_patches[name] = content
    return all_patches
