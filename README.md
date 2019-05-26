# Grassland for Docker

[![grassland-docker banner from the documentation](https://i.imgur.com/8LthQKT.png)](https://austinheap.github.io/grassland-docker/)

[![License](https://img.shields.io/github/license/austinheap/grassland-docker.svg)](LICENSE.md)
[![Release](https://img.shields.io/github/release/austinheap/grassland-docker.svg)](https://github.com/austinheap/grassland-docker/releases)
[![Pulls](https://img.shields.io/docker/pulls/austinheap/grassland.svg)](https://hub.docker.com/r/austinheap/grassland)
[![Stars](https://img.shields.io/docker/stars/austinheap/grassland.svg)](https://hub.docker.com/r/austinheap/grassland)
[![Layers](https://img.shields.io/microbadger/layers/austinheap/grassland.svg)](https://microbadger.com/images/austinheap/grassland)
[![Size](https://img.shields.io/microbadger/image-size/austinheap/grassland.svg)](https://microbadger.com/images/austinheap/grassland)
[![Automated](https://img.shields.io/docker/cloud/automated/austinheap/grassland.svg)](https://hub.docker.com/r/austinheap/grassland/builds)
[![Status](https://img.shields.io/docker/cloud/build/austinheap/grassland.svg)](https://hub.docker.com/r/austinheap/grassland/builds)

## Dockerfiles and scripts for Grassland network, based on configuration settings.

The purpose of this project is to create a set-it-and-forget-it Docker image that can be installed without much effort to access and contribute to the Grassland network. It is therefore highly opinionated but built for [configuration](#step-1-configure).

Grassland is an open-source, permissionless, peer-to-peer network of incentivised and anonymous computer vision software that turns video feeds from fixed-perspective cameras around the world into a (politically) stateless, indelible public record of the lives of people and the movement of physical assets as a simulated, real-time, 3D, bird's-eye-view similar to the games _SimCity®_ or _Civilization®_, but with the ability to rewind time and view events in the past.

This repo is not affiliated with the owners of the aforementioned software titles: they are owned by _EA Games_, _Firaxis_, and _Microsoft_, respectively.

## Table of Contents

* [Summary](#dockerfiles-and-scripts-for-grassland-network-based-on-configuration-settings)
* [Requirements](#requirements)
* [Installation](#installation)
    + [Step 1: Configure](#step-1-configure)
    + [Step 2: Initialize](#step-2-initialize)
    + [Step 3: Restart](#step-3-restart)
* [Usage](#usage)
* [FAQ](#faq)
    + [What does node calibration do?](#what-does-node-calibration-do)
    + [What is the proper way to calibrate a node?](#what-is-the-proper-way-to-calibrate-a-node)
    + [Why can't Docker for Mac see the web camera?](#why-cant-docker-for-mac-see-the-web-camera)
    + [Why doesn't camera X/Y/Z work?](#why-doesnt-camera-xyz-work)
    + [Why isn't it displaying anything?](#why-isnt-it-displaying-anything)
* [Credits](#credits)
* [Contributing](#contributing)
* [License](#license)

## Requirements

* [Docker](https://www.docker.com/get-started) `>=` 18.09.2
* [GNU Make](https://www.gnu.org/software/make/) `>=` 3.81

## Installation

### Step 1: Configure

Copy [`env.list`](env.list) to `env.local`, edit the values and validate them using:

```sh
    $ docker run --interactive                    \
                 --tty                            \
                 --rm                             \
                 --env-file=env.local             \
                 --device=/dev/video0:/dev/video0 \
                   austinheap/grassland validate
```

### Step 2: Initialize

Initialize Grassland, the AWS services, and [calibrate the camera](#what-does-node-calibration-do) using:

```sh
    $ docker run --name=grassland                 \
                 --restart=always                 \
                 --env-file=env.local             \
                 --device=/dev/video0:/dev/video0 \
                 --cpus=4.0                       \ # Limit CPU usage
                 --memory=4g                      \ # Limit memory usage
                   austinheap/grassland
```

Once initialized a video feed opens showing real-time bounding boxes around detected objects. Calibrate the camera with the GUI (`http://<docker-host-ip>:3000/`) and validate it using:

```sh
    $ docker exec --interactive --tty grassland grassland validate:calibration
```

### Step 3: Restart

Restart the container (`docker restart grassland`) to bring Grassland up in 'ONLINE' mode. This will not open a real-time video display but will start the web GUI. If the video display opens again then calibration wasn't successful and your container is re-initializing.

## Usage

The following commands are available for controlling the container:

```sh
    $ docker exec --interactive --tty grassland help

              grassland-docker  .:.  v0.1.0
    -----------------------------------------------------

    help                - Display this help
    version             - Display the version
    shell               - Open a shell
    start               - Start the service

    init                - Initialize instance
    init:calibration    - Initialize calibration data
    init:config         - Initialize config files
    init:data           - Initialize data files
    init:lambda         - Initialize AWS Lambda stack
    init:s3             - Initialize AWS S3 buckets

    destroy             - Destroy instance
    destroy:calibration - Destroy calibration data
    destroy:data        - Destroy data files
    destroy:lambda      - Destroy AWS Lambda stack
    destroy:s3          - Destroy AWS S3 buckets

    validate            - Validate instance
    validate:aws        - Validate AWS credentials
    validate:camera     - Validate camera device
    validate:data       - Validate downloaded data
    validate:lambda     - Validate AWS Lambda stack
    validate:s3         - Validate AWS S3 buckets
    validate:variables  - Validate environmental variables
    validate:versions   - Validate package versions
```

The following envrionmental variables are available for configuring the container:

|             Name            |   Type   | Required |                            Description                            |           Example           |
|-----------------------------|:--------:|:--------:|-------------------------------------------------------------------|:---------------------------:|
| `AWS_DEFAULT_REGION`        | `string` | **True** | Specifies the AWS Region to send requests to.                     | `us-west-1`                 |
| `AWS_ACCESS_KEY_ID`         | `string` | **True** | Specifies the AWS access key associated with an IAM user or role. | `XXXXXXXXXXXXXXXXXX`        |
| `AWS_SECRET_ACCESS_KEY`     | `string` | **True** | Specifies the AWS secret key associated with the AWS access key.  | `AXXZZZZZZZZZZZZZZZZZZ`     |
| `CONTAINER_DEBUG`           |  `bool`  |   False  | Enables verbose output when present.                              | `true`                      |
| `CONTAINER_QUIET`           |  `bool`  |   False  | Disables convenience output when present.                         | `false`                     |
| `DISPLAY`                   | `string` |   False  | Specifies the X Window Server for output.                         | `host.docker.internal:0`    |
| `GRASSLAND_FRAME_S3_BUCKET` | `string` | **True** | Specifies the S3 bucket to queue unprocessed frames in.           | `grassland-frame-s3-bucket` |
| `GRASSLAND_MODEL_S3_BUCKET` | `string` | **True** | Specifies the S3 bucket to store model data in.                   | `grassland-model-s3-bucket` |
| `MapboxAccessToken`         | `string` | **True** | Specifies the Mapbox access token for Webpack.                    | `pk.XXXXXXXXXXXXXXXXXX...`  |

## FAQ

### What does node calibration do?

Calibrating a Grassland instance lets the node know where the camera its viewing is positioned in the real world. When initializing, the node GUI simulates a 3D map of the world to virtually set a position and viewing angle that matches that of the camera in the real world.

Improper calibration in future versions _could_ cause the node to fail and _should_ cause objects tracked by the node to be rejected by the network ledger.

### What is the proper way to calibrate a node?

From the [`node_lite` documentation](https://github.com/grasslandnetwork/node_lite#step-3-calibrate-the-node):

> Once the map loads, use your mouse's scroll wheel to zoom and the left and right mouse buttons to drag and rotate the map until you've adjusted your browsers view of the map to match the position and orientation of your camera in the real world. Once you've narrowed it down, click on the 'CALIBRATION' toggle button. The GUI's frame dimensions will adjust to match your camera frame's dimensions. Continue adjusting your position until it matches the position and orientation of the real precisely.
> 
> As you're adjusting, your node should be receiving new calibration measurements and placing tracked objects on the GUI's map. Continue adjusting while referring to the node's video display until objects tracked in the video display are in their correct positions in the GUI's map.
> 
> In other words, you should have the video window that shows you the video that's streaming from the camera up on your computer screen (because the command you used to start the node included the "--display 1" option). Using your mouse, align the virtual map's viewport so it's looking from exact the same vantage point (latitiude, longitude, altitude, angle etc.) as the real camera is in real life.
> 
> Once that's done, your calibration values should be set inside the node's database. Now click the 'CALIBRATION' toggle button again to turn CALIBRATING mode off.

### Why isn't it displaying anything?

If a window with the video feed and detected objects (in bounding boxes) then the X server cannot be reached by the container. Instructions for that are beyond the scope of this project but [Google is your friend](http://lmgtfy.com/?q=docker+x+application+gui). Make sure to exported the `DISPLAY` environmental variable with the correct location.

### Why can't Docker for Mac see the web camera?

Docker for Mac [uses HyperKit](https://docs.docker.com/docker-for-mac/faqs/#what-is-the-benefit-of-hyperkit) for virtualization which is not compatible with [AVFoundation in macOS](https://developer.apple.com/av-foundation/). The fastest workaround is to use [`docker-machine`](https://formulae.brew.sh/formula/docker-machine) with [this purpose-built `boot2docker` ISO](https://github.com/Alexoner/boot2docker/releases/download/v17.06.0-ce-usb-rc5/boot2docker.iso), as it includes the `uvcvideo.ko` kernel module not found in the official distribution. As [explained](https://stackoverflow.com/a/44720836) by the author:

```sh
docker-machine create --driver virtualbox \
                      --virtualbox-boot2docker-url http://bit.ly/boot2uvcvideo \
                        default
```
> Then install the VirtualBox extension, [attach the webcam device](https://www.virtualbox.org/manual/ch09.html#webcam-passthrough), you are good to go!

### Why doesn't camera X/Y/Z work?

If the Docker host cannot see the device (i.e.: has the correct drivers for the device) it will not function. Most [UVC devices](https://en.wikipedia.org/wiki/List_of_USB_video_class_devices) however will function out-of-the-box. Cameras that do not function likely require customizations _outside the scope of this project_ or _will not work at all_ inside Docker without 1) running in the container in privileged mode and 2) breaking portability across Docker hosts.

## Credits

This is a fork of [janza/docker-python3-opencv](https://github.com/janza/docker-python3-opencv), which was a fork of [docker-library/python](https://github.com/docker-library/python), which was based on earlier work.

- [janza/docker-python3-opencv Contributors](https://github.com/janza/docker-python3-opencv/graphs/contributors)
- [docker-library/python Contributors](https://github.com/docker-library/python/graphs/contributors)

The Grassland software is developed by [@grasslandnetwork](https://github.com/grasslandnetwork).

- [grasslandnetwork/node_lite Contributors](https://github.com/grasslandnetwork/node_lite/graphs/contributors)
- [grasslandnetwork/node_lite_object_detection Contributors](https://github.com/grasslandnetwork/node_lite/graphs/contributors)

## Contributing

[Pull requests](https://github.com/austinheap/grassland-docker/pulls) welcome! Please see [the contributing guide](CONTRIBUTING.md) for more information.

## License

The MIT License (MIT). Please see the [license file](LICENSE.md) for more information.
