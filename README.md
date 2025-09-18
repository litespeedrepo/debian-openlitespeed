
# The OpenLiteSpeed
OpenLiteSpeed combines speed, security, scalability, optimization and simplicity in one friendly open-source package.

[<img src="https://img.shields.io/badge/slack-LiteSpeed-blue.svg?logo=slack">](litespeedtech.com/slack)

|Architecture| OpenLiteSpeed  |
|----------------------------------|----------------------------------------------------------------------------------------------------------|
| **AMD64** | ![AMD64](https://img.shields.io/github/actions/workflow/status/litespeedrepo/debian-openlitespeed/self-host-amd-build.yml?branch=main&label=build) |
| **ARM64** | ![ARM64](https://img.shields.io/github/actions/workflow/status/litespeedrepo/debian-openlitespeed/self-host-arm-build.yml?branch=main&label=build) |

## Prebuilt packages 
The easiest way to get up and running with OpenLiteSpeed is to use the LiteSpeed Repository. The LiteSpeed Repository comes with prebuilt PHP packages with LiteSpeed support built in.
[Document Link](https://docs.openlitespeed.org/installation/repo/)

## Building custom PHP from local
To build a custom package on a local server. 
1. Install git, docker, pbuilder and debhelper
2. Start container with command, `docker run -d --name packagebuild --user root --cap-add SYS_ADMIN --security-opt seccomp=unconfined --security-opt apparmor=unconfined -it eggcold/debian-build`
3. Login to the container: `docker exec -it packagebuild bash`
4. clone the repo or your forked repo, `git clone https://github.com/litespeedrepo/debian-openlitespeed.git`
5. Go to the project: `cd debian-openlitespeed`
6. Run example command to build, e.g. openlitespeed package for bookworm distribution: `./build.sh openlitespeed bookworm amd64`
7. Result deb will be stored under, e.g. **build/openlitespeed/1.8.4-1/build-result/bookworm** folder

## Support, Feedback, and Collaboration

* Join [the GoLiteSpeed Slack community](https://litespeedtech.com/slack) for real-time discussion
* Post to [the LiteSpeed Forums](https://litespeedtech.com/support/forum/) for community support
* Report problems with these project in [the project's Issues](https://github.com/litespeedrepo/debian-openlitespeed/issues)
* Contribute to these project with [a Pull Request](https://github.com/litespeedrepo/debian-openlitespeed/pulls). This project is intended to be a safe, welcoming space for collaboration.