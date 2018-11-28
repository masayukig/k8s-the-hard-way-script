k8s-the-hard-way-script
=======================

This executes the `kubernetes-the-hard-way`_ automatically.

.. _kubernetes-the-hard-way: https://github.com/kelseyhightower/kubernetes-the-hard-way/

Usage
-----

To run the all of these script, just run ``run.sh``::

    $ ./run.sh

WARNING
-------

For now, the ``run.sh`` doesn't cleanup the GCP resources. So, if you want to cleanup them,
you need to run ``14-cleanup.sh`` manually.
