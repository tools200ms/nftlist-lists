#!/bin/bash
[ -n "$DEBUG" ] && [[ $(echo "$DEBUG" | tr '[:upper:]' '[:lower:]') =~ ^y|yes|1|on$ ]] && \
  set -xe || set -e

PACKAGE_NAME="nftlist-lists"
VERSION="1.0"
ARCH="all"  # Change if architecture-specific
INSTALL_DIR="/var/lib/nftlist"
BUILD_DIR="$(pwd)/build"
DIST_DIR="$(pwd)/dist"
FILES_TO_INSTALL="$(pwd)/data/*"  # Modify to include the actual files

# Ensure directories exist
rm -rf "$BUILD_DIR" "$DIST_DIR/*"
mkdir -p "$BUILD_DIR/$INSTALL_DIR" "$DIST_DIR"

# Copy files to build directory
cp -r $FILES_TO_INSTALL "$BUILD_DIR/$INSTALL_DIR/"

echo "📦 Building packages for $PACKAGE_NAME version $VERSION"

# ---- 1️⃣ Build .tar.gz ----
echo "🗜️ Creating tar.gz package..."
tar czf "$DIST_DIR/${PACKAGE_NAME}-${VERSION}.tar.gz" -C "$BUILD_DIR" .

# ---- 2️⃣ Build Debian Package (.deb) ----
DEB_DIR="$BUILD_DIR/debian"
mkdir -p "$DEB_DIR/DEBIAN" "$DEB_DIR/$INSTALL_DIR"
cp -r "$BUILD_DIR/$INSTALL_DIR" "$DEB_DIR/$INSTALL_DIR"

cat <<EOF > "$DEB_DIR/DEBIAN/control"
Package: $PACKAGE_NAME
Version: $VERSION
Architecture: $ARCH
Maintainer: You <you@example.com>
Description: NFT List Storage
EOF

dpkg-deb --build "$DEB_DIR" "$DIST_DIR/${PACKAGE_NAME}_${VERSION}.deb"

# ---- 3️⃣ Build Alpine Package (.apk) ----
APK_DIR="$BUILD_DIR/alpine"
mkdir -p "$APK_DIR" "$APK_DIR/$INSTALL_DIR"
cp -r "$BUILD_DIR/$INSTALL_DIR" "$APK_DIR/$INSTALL_DIR"

cat <<EOF > "$APK_DIR/APKBUILD"
# Contributor: You <you@example.com>
# Maintainer: You <you@example.com>
pkgname=$PACKAGE_NAME
pkgver=$VERSION
pkgrel=0
pkgdesc="NFT List Storage"
arch="all"
license="GPL"
depends=""
source="data/*"
build() { return 0; }
package() {
    install -d "\$pkgdir/$INSTALL_DIR"
    cp -r "$BUILD_DIR/$INSTALL_DIR" "\$pkgdir/$INSTALL_DIR"
}
EOF

chown -R user $APK_DIR
su user -c "abuild -r -C $APK_DIR"

mv "$APK_DIR"/*.apk "$DIST_DIR/"

# ---- 4️⃣ Build Fedora RPM (.rpm) ----
RPM_DIR="$BUILD_DIR/rpm"
mkdir -p "$RPM_DIR/{BUILD,RPMS,SOURCES,SPECS,SRPMS}" "$RPM_DIR/$INSTALL_DIR"
cp -r "$BUILD_DIR/$INSTALL_DIR" "$RPM_DIR/$INSTALL_DIR"
tar czf "$RPM_DIR/SOURCES/${PACKAGE_NAME}-${VERSION}.tar.gz" -C "$BUILD_DIR" .

cat <<EOF > "$RPM_DIR/SPECS/${PACKAGE_NAME}.spec"
Name: $PACKAGE_NAME
Version: $VERSION
Release: 1%{?dist}
Summary: NFT List Storage
License: GPL
BuildArch: noarch
Source0: ${PACKAGE_NAME}-${VERSION}.tar.gz

%description
NFT List Storage for managing lists in /var/lib/nftlist.

%prep
%setup -q

%install
mkdir -p %{buildroot}/$INSTALL_DIR
cp -r * %{buildroot}/$INSTALL_DIR

%files
$INSTALL_DIR/*

%changelog
EOF

rpmbuild --define "_topdir $RPM_DIR" -bb "$RPM_DIR/SPECS/${PACKAGE_NAME}.spec"
mv "$RPM_DIR/RPMS/noarch/"*.rpm "$DIST_DIR/"

echo "✅ All packages built successfully! Find them in $DIST_DIR"
