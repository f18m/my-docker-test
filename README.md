# my-docker-test
Internal test project for shipping C++ applications inside optimized dockers

The same result in this test project is obtained in 2 ways (just for didactive purposes):

1) using a 2-stage build process (Dockerfile.build and then Dockerfile.production)
2) using a single multistage process (Dockerfile.multistage)

## Some useful links

- https://www.eclipse.org/community/eclipse_newsletter/2017/april/article1.php
- https://github.com/larsks/dockerize
- https://techbeacon.com/app-dev-testing/5-critical-elements-building-next-generation-cloud-native-apps
- https://medium.com/@andreybronin/modern-cloud-native-c-microservice-part-1-intro-b71de543f94b
