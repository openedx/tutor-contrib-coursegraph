"""
Generate release-able Python egg.
"""

import io
import os
from typing import Any, Dict, List, Set

from setuptools import setup

HERE = os.path.abspath(os.path.dirname(__file__))


def load_requirements(*requirements_paths: str) -> List[str]:
    """
    Load all requirements from the specified requirements files.
    """
    requirements: Set[str] = set()
    for path in requirements_paths:
        with open(path, encoding="utf-8") as reqs:
            requirements.update(
                line.split("#")[0].strip()
                for line in reqs
                if is_requirement(line.strip())
            )
    return list(requirements)


def is_requirement(line: str) -> bool:
    """
    Return True if the requirement line is a package requirement;
    that is, it is not blank, a comment, a URL, or an included file.
    """
    return bool(line) and not line.startswith(("-r", "#", "-e", "git+", "-c"))


def load_readme() -> str:
    """
    Slurp README into a string.
    """
    with io.open(
        os.path.join(HERE, "README.rst"), "rt", encoding="utf8"
    ) as readme_file:
        return readme_file.read()


def load_about() -> Dict[str, Any]:
    """
    Execute __about__.py in order to load version of package. Return globals.
    """
    about: Dict[str, Any] = {}
    with io.open(
        os.path.join(HERE, "tutorcoursegraph", "__about__.py"),
        "rt",
        encoding="utf-8",
    ) as about_file:
        exec(about_file.read(), about)  # pylint: disable=exec-used
    return about


ABOUT = load_about()


setup(
    name="tutor-contrib-coursegraph",
    version=ABOUT["__version__"],
    url="https://github.com/openedx/tutor-contrib-coursegraph",
    project_urls={
        "Code": "https://github.com/openedx/tutor-contrib-coursegraph",
        "Issue tracker": "https://github.com/openedx/tutor-contrib-coursegraph/issues",
    },
    license="AGPLv3",
    author="The Center for Reimagining Learning",
    description="A Tutor plugin that enables the Open edX CourseGraph tool",
    long_description=load_readme(),
    long_description_content_type="text/x-rst",
    packages=["tutorcoursegraph"],
    include_package_data=True,
    python_requires=">=3.8",
    install_requires=load_requirements("requirements/base.in"),
    entry_points={"tutor.plugin.v0": ["coursegraph = tutorcoursegraph.plugin"]},
    classifiers=[
        "Development Status :: 4 - Beta",
        "Environment :: Console",
        "Environment :: Web Environment",
        "Intended Audience :: Developers",
        "Intended Audience :: Education",
        "License :: OSI Approved :: GNU Affero General Public License v3",
        "Operating System :: OS Independent",
        "Programming Language :: Python",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Topic :: Education",
        "Typing :: Typed",
    ],
)
