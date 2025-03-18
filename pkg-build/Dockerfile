# Start with a minimal Alpine base image
FROM 200ms/alpinenet_dev2:latest AS package_builder

env FEATURE='dev2fs update2gnu'
env DEV2FS_SOURCE='/build.dist'
env DEV2FS_TARGET='/build/dist'

env PKG_ALPINE_SIG_KEY_PATH='/home/user/.abuild/SIG-KEY.rsa'

# Drop rc.local .start file:
COPY ./alpine-sig-key-check.start /etc/local.d/
RUN chmod +x /etc/local.d/alpine-sig-key-check.start
RUN rc-update add local default

# Install required build tools
RUN apk add --no-cache \
    doas shadow dpkg dpkg-dev rpm build-base abuild fakeroot tar gzip

# Set up an abuild user for Alpine package building
# Add user 'user'
RUN feat_adduser
RUN su user -c "mkdir -p ~/${PKG_ALPINE_SIG_KEY_PATH}"
RUN usermod -aG abuild user

# Set up working directory
WORKDIR /build
RUN mkdir -p ${DEV2FS_TARGET}

# Default command: show installed tools
CMD echo "✅ Environment ready for building .deb, .rpm, .apk, and .tar.gz packages!"
