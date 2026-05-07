.. code::console

    $ docker login -u trutzio dhi.io
    $ docker image pull dhi.io/etcd:3.6.11-dev
    $ docker run --detach --name etcd dhi.io/etcd:3.6.11-dev
    $ docker exec -it etcd bash
    $ https://etcd.io/
    $ sudo apt search etcd
    $ sudo apt install etcd-client
