"""
Implements CourseGraph plugin via Tutor Plugin API v0.

Important exports: templates, config, hooks, patches, and __version__.
"""

from typing import Dict
from importlib import resources

from .__about__ import __version__

TEMPLATES = str(resources.files("tutorcoursegraph").joinpath("templates"))

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
        "RUN_NEO4J": True,
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
    patches_dir = resources.files("tutorcoursegraph").joinpath("patches")

    for path in patches_dir.iterdir():
        if path.is_file():
            with open(str(path), encoding="utf-8") as patch_file:
                name = path.name
                content = patch_file.read()
                all_patches[name] = content
    return all_patches
