"""
Implements CourseGraph plugin via Tutor Plugin API v0.

Important exports: templates, config, hooks, patches, and __version__.
"""

import os
from glob import glob
from typing import Dict

import pkg_resources

from .__about__ import __version__

templates = pkg_resources.resource_filename("tutorcoursegraph", "templates")

config = {
    "add": {
        "NEO4J_PASSWORD": "{{ 20|random_string }}",
    },
    "defaults": {
        "VERSION": __version__,
        "NEO4J_VERSION": "3.5.28",
        "NEO4J_DOCKER_IMAGE": "{{ DOCKER_REGISTRY }}neo4j:{{ COURSEGRAPH_NEO4J_VERSION }}",
        "NEO4J_HOST": "coursegraph.{{ LMS_HOST }}",
        "DUMP_COURSE_ON_PUBLISH": True,
    },
}

hooks = {
    "remote-image": {"coursegraph": "{{ COURSEGRAPH_NEO4J_DOCKER_IMAGE }}"},
    "init": ["cms"],
}


def patches() -> Dict[str, str]:
    """
    Load mapping from patch file names to their contents.
    """
    all_patches = {}
    patches_dir = pkg_resources.resource_filename("tutorcoursegraph", "patches")
    for path in glob(os.path.join(patches_dir, "*")):
        with open(path, encoding="utf-8") as patch_file:
            name = os.path.basename(path)
            content = patch_file.read()
            all_patches[name] = content
    return all_patches
