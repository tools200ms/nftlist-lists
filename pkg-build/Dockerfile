# Start with a minimal Alpine base image
FROM 200ms/alpinenet_dev2:latest AS builder

# Install required build tools
RUN apk add --no-cache \
    dpkg dpkg-dev rpm build-base abuild fakeroot tar gzip

# Set up an abuild user for Alpine package building
# Add user 'user'
RUN feat_adduser
#RUN adduser -DS abuild && \
#    echo "abuild ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up working directory
WORKDIR /build

# Default command: show installed tools
CMD echo "✅ Environment ready for building .deb, .rpm, .apk, and .tar.gz packages!"
