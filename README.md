# my-docker-test
Internal test project for shipping C++ applications inside optimized dockers

The same result in this test project is obtained in 2 ways (just for didactive purposes):

1) using a 2-stage build process (Dockerfile.stage1-build and then Dockerfile.stage2-production)
2) using a single multistage process (Dockerfile.multistage)
3) using a shared volume (Dockerfile.sharedvolume and then Dockerfile.stage2-production)

## Some useful links

- https://www.eclipse.org/community/eclipse_newsletter/2017/april/article1.php
- https://github.com/larsks/dockerize
- https://techbeacon.com/app-dev-testing/5-critical-elements-building-next-generation-cloud-native-apps
- https://medium.com/@andreybronin/modern-cloud-native-c-microservice-part-1-intro-b71de543f94b
