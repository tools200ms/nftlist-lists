#!/bin/bash
[ -n "$DEBUG" ] && [[ $(echo "$DEBUG" | tr '[:upper:]' '[:lower:]') =~ ^y|yes|1|on$ ]] && \
  set -xe || set -e

PACKAGE_NAME="nftlist-lists"
PROGRAM_URL="https://github.com/tools200ms/nftlist-lists"
VERSION="1.0"
LICENSE="MIT"

DESCRIPTION="Public services IP list for Nftlist (and not only)."
CONTRIBUTOR="Mateusz Piwek <barnaba@200ms.net>"
MAINTAINER="Mateusz Piwek <barnaba@200ms.net>"

ARCH="all"  # Change if architecture-specific
INSTALL_DIR="var/lib/nftlist"
BUILD_DIR="$(pwd)/build"
DIST_DIR="$(pwd)/dist"
# To be always used with '*' asterix!:
#
FILES_TO_INSTALL="$(pwd)/data/*"  # Modify to include the actual files
FILES_TO_INSTALL_SHA="$(find $FILES_TO_INSTALL -printf '%P\n' -name "*.list" -type f -exec echo "install -Dm755 \"\$srcdir/{}\" \"\$pkgdir/var/lib/nftlist/{}\"" \;)"

# Ensure directories exist
rm -rf "$BUILD_DIR" "$DIST_DIR/*"
#mkdir -p "$BUILD_DIR/$INSTALL_DIR" "$DIST_DIR"

echo "📦 Building packages for $PACKAGE_NAME version $VERSION"

# ---- 1️⃣ Build .tar.gz ----
echo "🗜️ Creating tar.gz package..."
TAR_DIR="$BUILD_DIR/tar"
# Copy files to build directory
mkdir -p "${TAR_DIR}/$INSTALL_DIR"
cp -r $FILES_TO_INSTALL "${TAR_DIR}/${INSTALL_DIR}/"

tar czf "$DIST_DIR/${PACKAGE_NAME}-${VERSION}.tar.gz" -C "$TAR_DIR" .

# ---- 2️⃣ Build Debian Package (.deb) ----
DEB_DIR="$BUILD_DIR/deb"
mkdir -p "$DEB_DIR/DEBIAN"
cp -r $TAR_DIR/* "$DEB_DIR/"

cat <<EOF > "$DEB_DIR/DEBIAN/control"
Package: $PACKAGE_NAME
Version: $VERSION
Architecture: $ARCH
Maintainer: $CONTRIBUTOR
Description: $DESCRIPTION
EOF

dpkg-deb --build "$DEB_DIR" "$DIST_DIR/${PACKAGE_NAME}_${VERSION}.deb"

# ---- 3️⃣ Build Alpine Package (.apk) ----
APK_DIR="$BUILD_DIR/apk"
mkdir -p "$APK_DIR"
#cp -r $FILES_TO_INSTALL "$APK_DIR/${PACKAGE_NAME}/"

# $(cd $APK_DIR; find . -type f ! -name APKBUILD | cut -c 3-)

cd ${APK_DIR}

cat <<EOF > "./APKBUILD"
# Contributor: $CONTRIBUTOR
# Maintainer: $MAINTAINER
pkgname=$PACKAGE_NAME
pkgver=$VERSION
pkgrel=0
pkgdesc="$DESCRIPTION"
arch="all"
license="$LICENSE"
url="$PROGRAM_URL"
depends=""
makedepends=""
source="$FILES_TO_INSTALL
"
build() { return 0; }

check() {
    for file in "$srcdir"/${PACKAGE_NAME}/*; do
        if [ -f "$file" ]; then
            echo "Testing: $file"

            # Check if file is empty
            if [ ! -s "$file" ]; then
                echo "Test failed: $file is empty"
                return 1
            fi

            # Check if file is a text file
            if ! file "$file" | grep -q "text"; then
                echo "Test failed: $file is not a text file"
                return 1
            fi

            # Count lines in file
            line_count=$(wc -l < "$file")

            if [ "$line_count" -le 2 ] || [ "$line_count" -ge 100000 ]; then
                echo "Test failed: $file has illegal line no ($line_count)"
                return 1
            fi
        fi
    done
}


package() {
$(cd $APK_DIR/nftlist; find * -name "*.list" -type f -exec echo "install -Dm755 \"\$srcdir/{}\" \"\$pkgdir/var/lib/nftlist/{}\"" \;)
}

sha512sums="$(cd $APK_DIR/src; find * -type f -exec sha512sum {} \;)
"
EOF

apk_key_path="$PKG_ALPINE_SIG_KEY_PATH"

if [ ! -e $(dirname ${apk_key_path}) ]; then
  mkdir -p "/home/user/.abuild/"
elif [ -d $(dirname ${apk_key_path}) ]; then
  # ensure access to '.abuild' directory
  chown user:user $(dirname ${apk_key_path})
else
  echo "File: '/home/user/.abuild/' must be a directory."
  exit 4
fi

cat <<EOF > /home/user/.abuild/abuild.conf
# Automatically generated abuild configuration file

# Define the RSA signing key
PACKAGER_PRIVKEY="$apk_key_path"

# Set the packager name and email (customize as needed)
PACKAGER="Your Name <your.email@example.com>"

# Define other build options if needed
JOBS=4  # Adjust based on CPU cores for faster builds

# Uncomment to enable debug mode
# DEBUG=1
EOF

chown -R user:user ${APK_DIR}

if [ ! -f "$apk_key_path" ]; then
  echo "Apk key has not been found, add or generate with 'abuild-keygen'"
  echo "Expectet key location: $apk_key_path"
  exit 2
fi

su user -c "abuild-keygen -a -n"
su user -c "abuild -r -C ${APK_DIR} && abuild clean -C ${APK_DIR}" || res=$?

if [ $res -ne 0 ]; then
  echo "ERROR at APK buiild, but ignorring."
fi

find /home/user/packages/build/ -name '*.apk' -exec mv {} "${DIST_DIR}/" \;


exit 0

# ---- 4️⃣ Build Fedora RPM (.rpm) ----
RPM_DIR="$BUILD_DIR/rpm"
mkdir -p ${RPM_DIR}/{BUILD,RPMS,SOURCES,SPECS,SRPMS} "$RPM_DIR/$INSTALL_DIR"
cp -r "$BUILD_DIR/$INSTALL_DIR" "$RPM_DIR/$INSTALL_DIR"
tar czf ${RPM_DIR}/SOURCES/${PACKAGE_NAME}-${VERSION}.tar.gz -C "${BUILD_DIR}" .

cat <<EOF > "$RPM_DIR/SPECS/${PACKAGE_NAME}.spec"
Name: $PACKAGE_NAME
Version: $VERSION
Release: 1%{?dist}
Summary: NFT List Storage
License: $LICENSE
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
