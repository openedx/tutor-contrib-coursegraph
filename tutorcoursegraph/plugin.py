from glob import glob
import os
import pkg_resources

import click

from .__about__ import __version__

templates = pkg_resources.resource_filename(
    "tutorcoursegraph", "templates"
)

config = {
    "add": {
        "NEO4J_INITIAL_PASSWORD": "{{ 20|random_string }}",
    },
    "defaults": {
        "VERSION": __version__,
        "NEO4J_VERSION": "3.5.28",
        "NEO4J_DOCKER_IMAGE": "{{ DOCKER_REGISTRY }}neo4j:{{ COURSEGRAPH_NEO4J_VERSION }}",
        "HOST": "coursegraph.{{ LMS_HOST }}",
    },
}

hooks = {
    "remote-image": {"coursegraph": "{{ COURSEGRAPH_DOCKER_IMAGE }}"},
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


@click.group(help="CourseGraph administration")
def command():
    pass


@command.command(help="Refresh CourseGraph from CMS")
def refresh():
    click.echo('this would refresh coursegraph!')
