![Code Testing](https://github.com/sipwise/rtpengine/workflows/Code%20Testing/badge.svg)
![Debian Package CI](https://github.com/sipwise/rtpengine/workflows/Debian%20Packaging/badge.svg)
![Coverity](https://img.shields.io/coverity/scan/sipwise-rtpengine.svg)

# What is rtpengine?

The [Sipwise](http://www.sipwise.com/) NGCP rtpengine is a proxy for RTP traffic and other UDP based
media traffic. It's meant to be used with the [Kamailio SIP proxy](http://www.kamailio.org/)
and forms a drop-in replacement for any of the other available RTP and media
proxies.

Currently the only supported platform is GNU/Linux.

## Mailing List

For general questions, discussion, requests for support, and community chat,
join our [mailing list](https://rtpengine.com/mailing-list). Please do not use
the Github issue tracker for this purpose.

## Features

* Media traffic running over either IPv4 or IPv6
* Bridging between IPv4 and IPv6 user agents
* Bridging between different IP networks or interfaces
* TOS/QoS field setting
* Customizable port range
* Multi-threaded
* Advertising different addresses for operation behind NAT
* In-kernel packet forwarding for low-latency and low-CPU performance
* Automatic fallback to normal userspace operation if kernel module is unavailable
* Support for *Kamailio*'s *rtpproxy* module
* Legacy support for old *OpenSER* *mediaproxy* module
* HTTP, HTTPS, and WebSocket (WS and WSS) interfaces

When used through the *rtpengine* module (or its older counterpart called *rtpproxy-ng*),
the following additional features are available:

- Full SDP parsing and rewriting
- Supports non-standard RTCP ports (RFC 3605)
- ICE (RFC 5245) support:
  + Bridging between ICE-enabled and ICE-unaware user agents
  + Optionally acting only as additional ICE relay/candidate
  + Optionally forcing relay of media streams by removing other ICE candidates
  + Optionally act as an "ICE lite" peer only
- SRTP (RFC 3711) support:
  + Support for SDES (RFC 4568) and DTLS-SRTP (RFC 5764)
  + AES-CM and AES-F8 ciphers, both in userspace and in kernel
  + HMAC-SHA1 packet authentication
  + Bridging between RTP and SRTP user agents
  + Opportunistic SRTP (RFC 8643)
  + Legacy non-RFC (dual `m=` line) best-effort SRTP
  + AES-GCM Authenticated Encryption (AEAD) (RFC 7714)
  + `a=tls-id` as per RFC 8842
- Support for RTCP profile with feedback extensions (RTP/AVPF, RFC 4585 and 5124)
- Arbitrary bridging between any of the supported RTP profiles (RTP/AVP, RTP/AVPF,
  RTP/SAVP, RTP/SAVPF)
- RTP/RTCP multiplexing (RFC 5761) and demultiplexing
- Breaking of BUNDLE'd media streams (draft-ietf-mmusic-sdp-bundle-negotiation)
- Recording of media streams, decrypted if possible
- Transcoding and repacketization
- Transcoding between RFC 2833/4733 DTMF event packets and in-band DTMF tones (and vice versa)
- Injection of DTMF events or PCM DTMF tones into running audio streams
- Playback of pre-recorded streams/announcements
- Transcoding between T.38 and PCM (G.711 or other audio codecs)
- Silence detection and comfort noise (RFC 3389) payloads
* Media forking
* Publish/subscribe mechanism for N-to-N media forwarding

There is also limited support for *rtpengine* to be used as a drop-in
replacement for *Janus* using the native Janus control protocol (see below).

*Rtpengine* does not (yet) support:

* ZRTP, although ZRTP passes through *rtpengine* just fine

## Documentation

Check our general documentation here:
* [Read-the-Docs](https://rtpengine.readthedocs.io/en/latest/)

For quick access, documentation for usage:
* [Compiling and Installing](https://rtpengine.readthedocs.io/en/latest/compiling_and_installing.html)
* [Usage](https://rtpengine.readthedocs.io/en/latest/usage.html)
* [Transcoding](https://rtpengine.readthedocs.io/en/latest/transcoding.html)
* [Call recording](https://rtpengine.readthedocs.io/en/latest/call_recording.html)
* [The NG Control Protocol](https://rtpengine.readthedocs.io/en/latest/ng_control_protocol.html)
* [The TCP-NG Control Protocol](https://rtpengine.readthedocs.io/en/latest/tcpng_control_protocol.html)
* [HTTP/WebSocket support](https://rtpengine.readthedocs.io/en/latest/http_websocket_support.html)
* [Janus Interface and Replacement Functionality](https://rtpengine.readthedocs.io/en/latest/janus_interface_and_replacement.html)

For quick access, documentation for development:
* [Architecture Overview](https://rtpengine.readthedocs.io/en/latest/architecture.html)
* [Unit-tests](https://rtpengine.readthedocs.io/en/latest/tests.html)
* [Troubleshooting Overview](https://rtpengine.readthedocs.io/en/latest/troubleshooting.html)
* [Glossary](https://rtpengine.readthedocs.io/en/latest/glossary.html)

## Sponsors

* [Dataport AöR](https://www.dataport.de/)

## Contribution

Every bit matters. Join us. Make the rtpengine community stronger.

---

## jambonz Fork

This is the jambonz fork of rtpengine. It differs from upstream only in package naming
(`jambonz-rtpengine` instead of `ngcp-rtpengine`) to avoid conflicts with Sipwise packages.

### Installing from the jambonz apt repository

```bash
# One-time setup
sudo install -d /etc/apt/keyrings
curl -fsSL https://jambonz-debian-packages.s3.us-east-2.amazonaws.com/jambonz.gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/jambonz.gpg
echo "deb [signed-by=/etc/apt/keyrings/jambonz.gpg] https://jambonz-debian-packages.s3.us-east-2.amazonaws.com/debian bookworm main" \
    | sudo tee /etc/apt/sources.list.d/jambonz.list
sudo apt-get update

# Install
sudo apt-get install jambonz-rtpengine
```

### Building Debian packages

**Automated (GitHub Actions):**

Push a tag matching `v*-jambonz*` to trigger builds for both amd64 and arm64:

```bash
git tag v14.1.1.8-jambonz5
git push origin v14.1.1.8-jambonz5
```

Or trigger manually from the Actions tab → "Build Debian Package" → "Run workflow".

**Local build (arm64 on Apple Silicon):**

If GitHub's arm64 runners aren't available, you can build locally on an M1/M2 Mac:

```bash
# Checkout the tag you want to build
git checkout v14.1.1.8-jambonz9  # replace with your tag

# Set the version (must match the tag, without the leading 'v')
VERSION=14.1.1.8-jambonz9

# Build
docker run --rm --platform linux/arm64 -v "$PWD":/src -w /src -e VERSION="$VERSION" debian:bookworm bash -c '
  apt-get update -qq
  DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential devscripts debhelper dh-sequence-dkms dkms systemd \
    default-libmysqlclient-dev discount gperf \
    libavcodec-dev libavfilter-dev libavformat-dev libavutil-dev \
    libbcg729-dev libbencode-perl libcjson-dev \
    libcrypt-openssl-rsa-perl libcrypt-rijndael-perl libcurl4-openssl-dev \
    libdigest-crc-perl libdigest-hmac-perl libevent-dev libglib2.0-dev \
    libhiredis-dev libio-multiplex-perl libio-socket-inet6-perl \
    libio-socket-ip-perl libiptc-dev libjson-glib-dev libjson-perl \
    libjwt-dev libmosquitto-dev libncurses-dev libnet-interface-perl \
    libopus-dev libpcap0.8-dev libpcre2-dev libsocket6-perl \
    libspandsp-dev libssl-dev libswresample-dev libsystemd-dev \
    libtest2-suite-perl liburing-dev libwebsockets-dev libwww-perl \
    libxtables-dev pandoc pkgconf python3 python3-websockets zlib1g-dev
  sed -i "0,/^jambonz-rtpengine (.*) bookworm/s//jambonz-rtpengine ($VERSION) bookworm/" debian/changelog
  dpkg-buildpackage -b -us -uc
  cp ../*.deb /src/
'

# Upload to S3
aws s3 cp jambonz-rtpengine_*_arm64.deb s3://jambonz-debian-packages/rtpengine/

# Trigger apt repo refresh
gh workflow run "Publish apt repository" --repo jambonz/apt-repo

# Check status (note: --repo is required since you're in the rtpengine directory)
gh run list --workflow=publish.yml --repo jambonz/apt-repo --limit 1

# Return to master
git checkout master
```

### Building RPM packages

Push a tag to trigger RPM builds for both x86_64 and aarch64, or trigger manually
from Actions → "Build RPM Package" → "Run workflow".
