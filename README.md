# my-docker-test
Internal test project for shipping C++ applications inside optimized dockers

The same result in this test project is obtained in 3 ways (just for didactive purposes):

1) using a 2-stage build process (Dockerfile.stage1-build and then Dockerfile.stage2-production)
2) using a single multistage process (Dockerfile.multistage)
3) using a shared volume (Dockerfile.sharedvolume and then Dockerfile.stage2-production)

The last option seems the most complete one as it allows for incremental builds and still produces
a docker image built from scratch with the bare-minimal runtime required.

By using "dive" you can verify the layers of the generated image and check that they're really down
to the minimals.


## Useful applications

1) dockerize (https://github.com/jwilder/dockerize) is able to collect all ELF required
dependencies and produce a docker out of them. PROBLEM: requires the ELF to have been
built on the baremetal -- we want to build the application inside a docker instead
to make sure we can build the application on any OS we like.

2) dive (https://github.com/wagoodman/dive) can be used to explore each layer of a Docker image


## Some useful links

- https://www.eclipse.org/community/eclipse_newsletter/2017/april/article1.php
- https://github.com/larsks/dockerize
- https://techbeacon.com/app-dev-testing/5-critical-elements-building-next-generation-cloud-native-apps
- https://medium.com/@andreybronin/modern-cloud-native-c-microservice-part-1-intro-b71de543f94b
