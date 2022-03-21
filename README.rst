CourseGraph plugin for `Tutor`_
----------------------------------------------------------------

|Neo4j|_ |plus| |Tutor|_

CourseGraph is a tool that allows `Open edX`_ developers and support specialists to inspect their platform instance's learning content. It consists of two simple components:

#. The `CourseGraph support application`_, which loads courses from the CMS's internal course store and dumps them into an instance of...
#. `Neo4j`_, a popular open-source graph database. Staff for an Open edX instance can query the course graph via Neo4j's Web console using the `Cypher`_ query language.

CourseGraph was initially an internal tool at edX, Inc., but as of the Maple release it was `shared with the greater Open edX community`_. This Tutor plugin aims to provide an easy mechanism for developers and operators to trial and deploy CourseGraph.

.. _Tutor: https://docs.tutor.overhang.io
.. _Open edX: https://openedx.org
.. _CourseGraph support application: https://github.com/openedx/edx-platform/tree/master/cms/djangoapps/coursegraph#coursegraph-support
.. _Neo4j: https://neo4j.com
.. _shared with the greater Open edX community: https://openedx.org/blog/announcing-coursegraph-a-new-tool-in-the-maple-release/
.. _Cypher: https://neo4j.com/developer/cypher/

.. |Neo4j| image:: https://dist.neo4j.com/wp-content/uploads/20210423072428/neo4j-logo-2020-1.svg
   :width: 300
   :align: middle
   :alt: Neo4j logo

.. |plus| image:: https://www.svgrepo.com/show/99205/plus-symbol-button.svg
   :width: 50
   :align: middle
   :alt: A plus sign, indicating the combination of Neo4j and Tutor

.. |Tutor| image:: https://overhang.io/static/img/tutor-logo.svg
   :width: 400
   :align: middle
   :alt: Tutor logo

Status & Contributing
=====================

tutor-contrib-coursegraph is being developed as part of the `Tutor Adoption Initiative`_. It is currently a work-in-progress, in that:

* It has been tested with Tutor in development mode.
* It has been partially tested with Tutor in local server mode.
* It does not yet work with Tutor in Kubernetes mode.

If you're interested in contributing, feel free to open an issue or a pull request. We'll try to give it a first look within a week.

.. _Tutor Adoption Initiative: https://openedx.atlassian.net/wiki/spaces/COMM/pages/3315335223/Tutor+Adoption+Initiative

Branches
********

This plugin uses the same branching model as Tutor:

.. list-table::

   - * ``nightly``
     * Latest development. Compatible with Tutor Nightly and Open edX master. Merged into ``master`` at each Open edX named release.

   - * ``master``
     * Latest stable release and patches. Compatible with Tutor master and latest Open edX named release. Merged into ``nightly`` continuously.

The syncing between branches is currently done manually.

If your change is backwards-compatible with the last Open edX named release, then propose it against ``master``. If not, then propose it against ``nightly``.

This repository aims to adhere to all relevant `Open edX Proposals`_, including `OEP-55, Conventional Commits`_.

.. _Open edX Proposals: https://open-edx-proposals.readthedocs.io
.. _OEP-55, Conventional Commits: https://open-edx-proposals.readthedocs.io/en/latest/best-practices/oep-0051-bp-conventional-commits.html

Installation
============

Install the latest stable version (requires the latest `Tutor release`_)::

  pip install git+https://github.com/kdmccormick/tutor-contrib-coursegraph

Or, install the latest nightly version (requires `Tutor Nightly`_)::

  pip install git+https://github.com/kdmccormick/tutor-contrib-coursegraph@nightly

Or, install the plugin to be hacked on::

  git clone git@github.com:kdmccormick/tutor-contrib-coursegraph
  cd tutor-contrib-coursegraph
  source {{ PATH TO A VIRTUAL ENVIRONMENT }}
  make dev-requirements

.. _Tutor release: https://github.com/overhangio/tutor/releases
.. _Tutor Nightly: https://docs.tutor.overhang.io/tutorials/nightly.html

Setup
=====

Enable the plugin and re-generate your Tutor environment::

    tutor plugins enable coursegraph
    tutor config save

Then, run initialization in order to dump your platform's existing courses into CourseGraph::

    tutor [dev|local|k8s] init --limit=coursegraph

Start CourseGraph::

    tutor [dev|local|k8s] start coursegraph

Usage
=====

Once CourseGraph is started and courses have been dumped to it, the tool can be viewed at::

  http://coursegraph.{{ LMS_HOST }}

For example, if your LMS is at ``openedx.example.edu`` and you're using the default Neo4j HTTP port, that'd be::

  http://coursegraph.openedx.example.edu:7474

At the prompt, your credentials should be:

.. list-table::

   * - **Username**
     - ``"neo4j"``
   * - **Password**
     - ``$(tutor config printvalue COURSEGRAPH_NEO4J_PASSWORD)``

Now that you're in, try `querying your courses`_!

.. _querying your courses: https://github.com/openedx/edx-platform/tree/master/cms/djangoapps/coursegraph#querying-coursegraph

.. image:: https://lh5.googleusercontent.com/hTBEdYjUSiqsh8u8eG8us8X1XvYNUZQfvDgLcfYSh659muHd6TdH96z1eya-0OB0SlFx-2q6s02zIyar52wXMDRiR6cg6ySAG_XLDsqKgVsRVHxEXnC6hRFnf6lr_NmTiplFW_Wi
   :alt: The Neo4j Web interface can be used to visualize relationships between blocks in a course. Here, the query "MATCH (course)-[:PARENT_OF*]->(p:problem) WHERE p.data CONTAINS 'jsinput' RETURN * LIMIT 50" is used to visualize problem blocks that use custom JavaScript, along with their ancestry.


Operations
==========

Operating CourseGraph is fairly straightforward, especially if you treat CourseGraph data as a non-critical secondary view into the CMS's course data. That is: you should be willing to completely drop and re-generate the CourseGraph data stord in Neo4j. By doing so, you avoid needing to back up Neo4j, and you de-risk the Neo4j schema version upgrades that you'll need to perform over time with new Open edX releases.

By default, this plugin configures CMS to dump each course to CourseGraph whenever it is published, allowing you to "set and forget" the tool. You can disable this behavior by setting ``COURSEGRAPH_DUMP_COURSE_ON_PUBLISH`` to ``false``, regenerating your Tutor environment, and restarting CMS.

If you have disabled automatic dumping, then you'll need to periodically refresh the data in CourseGraph manually. You can do so via the CMS administration console at, under the **COURSE GRAPH COURSE DUMPS** page in the **COURSE GRAPH** app:

|coursegraph admin|
|coursegraph admin success|

Alternatively, you can skip the admin console by using a CMS management command::

  tutor [dev|local|k8s] exec coursegraph ./manage.py cms dump_to_neo4j

.. |coursegraph admin| image:: https://user-images.githubusercontent.com/3628148/153106921-0e8c404b-df88-4c15-afbe-26627873d43e.png
   :alt: CourseGraph dump page in CMS admin console, demonstrating that individual courses can be selected for dump

.. |coursegraph admin success| image:: https://user-images.githubusercontent.com/3628148/153107016-fc6354d8-1c61-4728-b0a4-59150a3bf7b2.png
   :alt: CourseGraph dump page in CMS admin console, showing message after course dumps are successfully enqueued

Configuration
*************

The Tutor plugin can be configured with several settings. The names of all settings below are prefixed with ``COURSEGRAPH_``.

.. list-table::
   :header-rows: 1

   * - **CourseGraph Setting**
     - **Type**
     - **Default**
     - **Description**
   * - ``NEO4J_PASSWORD``
     - str
     - (20 random characters)
     - *Initial* password set for Neo4j, and password used to connect to Neo4j. To change after initialization, password must be updated both here and manually within Neo4j.
   * - ``NEO4J_VERSION``
     - str
     - ``"3.5.28"``
     - Version of Neo4j to use. Appended to default image. Overriding ``NEO4J_DOCKER_IMAGE`` annuls this setting.
   * - ``NEO4J_DOCKER_IMAGE``
     - str
     - ``"docker.io/neo4j:3.5.28"``
     - Neo4j Docker image to be pulled and used. By default, based on your ``DOCKER_REGISTRY`` and ``COURSEGRAPH_NEO4J_VERSION``.
   * - ``NEO4J_HOST``
     - str
     - Prod: ``"coursegraph.www.openedx.com"``, Dev: ``"coursegraph.local.overhang.io"``
     - Hostname of CourseGraph. By default, based on your ``LMS_HOST``.
   * - ``NEO4J_BOLT_PORT``
     - int
     - ``7687``
     - Port to be used for Bolt connections to Neo4j
   * - ``NEO4J_HTTP_PORT``
     - int
     - ``7474``
     - Port to be used for HTTP connections to Neo4j, including Neo4j Web browser interface
   * - ``NEO4J_SECURE``
     - bool
     - ``true``
     - Should CMS use TLS when connecting to Neo4j over Bolt or HTTP?
   * - ``NEO4J_PROTOCOL``
     - str
     - ``"bolt"``
     - Protocol CMS will use to connect to Neo4j. Should be ``"http"`` or ``"bolt"``.
   * - ``DUMP_COURSE_ON_PUBLISH``
     - bool
     - ``true``
     - Should CMS automatically dump a course to CourseGraph whenever it's published? If disabled, you will instead need to periodically dump courses via the management command or admin console.


Development
===========

Upgrade version pins::

  make upgrade

Run just static checks::

  make test-format test-lint test-types

Run all tests::

  cp $(tutor config printroot)/config.yml tutor_config.bak.yml
  make test  # clobbers some Tutor configuration
  mv tutor_config.bak.yml $(tutor config printroot)/config.yml  # restore original config


License
=======

This software is licensed under the terms of the AGPLv3.
