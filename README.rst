CourseGraph plugin for `Tutor <https://docs.tutor.overhang.io>`_
----------------------------------------------------------------

CourseGraph is a tool that allows Open edX developers and support specialists to inspect their platform instance's learning content. It consists of two simple components:

#. The `CourseGraph support application`_, which loads courses from the CMS's internal course store and dumps them into an instance of...
#. `Neo4j`_, a popular open-source graph database. Staff for an Open edX instance can query the course graph via Neo4j's Web console using the `Cypher`_ query language.

CourseGraph was initially an internal tool at edX, Inc., but as of the Maple release it was `shared with the greater Open edX community`_. This Tutor plugin aims to provide an easy mechanism for developers and operators to trial and deploy CourseGraph.

.. _CourseGraph support application: https://github.com/openedx/edx-platform/tree/master/cms/djangoapps/coursegraph#coursegraph-support
.. _Neo4j: https://neo4j.com
.. _shared with the greater Open edX community: https://openedx.org/blog/announcing-coursegraph-a-new-tool-in-the-maple-release/
.. _Cypher: https://neo4j.com/developer/cypher/


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

  http://coursegraph.{{ LMS_HOST }}:{{ COURSEGRAPH_NEO4J_HTTP_PORT }}

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


Operations
==========

Operating CourseGraph is fairly straightforward. It is best if you view the data in CourseGraph as a "secondary view" into course data (which should be OK if dropped at any time) instead of as a critical data source. This makes backups unnecessary and lowers the operational risk of upgrading to newer Neo4j versions over time.

By default, this plugin configures CMS to dump each course to CourseGraph whenever it is published. You can disable this behavior by setting ``COURSEGRAPH_DUMP_COURSE_ON_PUBLISH`` to ``false``, regenerating your Tutor environment, and restarting CMS.

If you have disabled automatic dumping, then you'll need to periodically refresh the data in CourseGraph manually. You can do so via the CMS administration console at::

  http://{{ CMS_HOST }}/admin/coursegraph/coursegraphcoursedumps

or by using a CMS management command::

  tutor [dev|local|k8s] exec coursegraph ./manage.py cms dump_to_neo4j

Configuration
*************

.. list-table::
   :header-rows: 1

   * - **Setting**
     - **Type**
     - **Default**
     - **Description**
   * - ``COURSEGRAPH_NEO4J_PASSWORD``
     - str
     - (20 random characters)
     - *Initial* password set for Neo4j, and password used to connect to Neo4j. To change after initialization, password must be updated both here and manually within Neo4j.
   * - ``COURSEGRAPH_NEO4J_VERSION``
     - str
     - ``"3.5.28"``
     - Version of Neo4j to use. Appended to default image. Overriding ``COURSEGRAPH_NEO4J_DOCKER_IMAGE`` annuls this setting.
   * - ``COURSEGRAPH_NEO4J_DOCKER_IMAGE``
     - str
     - ``"docker.io/neo4j:3.5.28"``
     - Neo4j Docker image to be pulled and used. By default, based on your ``DOCKER_REGISTRY`` and ``COURSEGRAPH_NEO4J_VERSION``.
   * - ``COURSEGRAPH_NEO4J_HOST``
     - str
     - ``"coursegraph.www.openedx.com"``
     - Hostname of CourseGraph. By default, based on your ``LMS_HOST``.
   * - ``COURSEGRAPH_NEO4J_BOLT_PORT``
     - int
     - ``7687``
     - Port to be used for Bolt connections to Neo4j
   * - ``COURSEGRAPH_NEO4J_HTTP_PORT``
     - int
     - ``7474``
     - Port to be used for HTTP connections to Neo4j, including Neo4j Web browser interface
   * - ``COURSEGRAPH_NEO4J_SECURE``
     - bool
     - ``true``
     - Should CMS use TLS when connecting to Neo4j over Bolt or HTTP?
   * - ``COURSEGRAPH_NEO4J_PROTOCOL``
     - str
     - ``"bolt"``
     - Protocol CMS will use to connect to Neo4j. Should be ``"http"`` or ``"bolt"``.
   * - ``COURSEGRAPH_DUMP_COURSE_ON_PUBLISH``
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


Contributing
============

tutor-contrib-coursegraph was developed as part of the `Tutor Adoption Initiative`_. It is currently mainained by me, Kyle McCormick.

If you're interested in contribution, feel free to open an issue or a pull request. I'll try to give it a first look within a week.

.. _Tutor Adoption Initiative: https://openedx.atlassian.net/wiki/spaces/COMM/pages/3315335223/Tutor+Adoption+Initiative


License
=======

This software is licensed under the terms of the AGPLv3.
