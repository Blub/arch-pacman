PACKAGE=arch-pacman
PACMANVER=5.0.2
DEBREL=1

SRCDIR=pacman
SRCTAR=${SRCDIR}.tgz

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)
GITVERSION:=$(shell cat .git/refs/heads/master)

DEB=${PACKAGE}_${PACMANVER}-${DEBREL}_amd64.deb
DEB2=${PACKAGE}-dev_${PACMANVER}-${DEBREL}_amd64.deb \
     ${PACKAGE}-dbg_${PACMANVER}-${DEBREL}_amd64.deb

DEBS= ${DEB} ${DEB2}

all: ${DEBS}
	echo ${DEBS}

${DEB}: ${SRCTAR}
	rm -rf ${SRCDIR}
	tar xf ${SRCTAR}
	cp -a debian ${SRCDIR}/debian
	echo "git clone git://projects.archlinux.org/pacman.git\\ngit checkout ${GITVERSION}" >  ${SRCDIR}/debian/SOURCE
	cd ${SRCDIR}; DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage -rfakeroot -b -us -uc
	lintian ${DEBS}

.PHONY: deb
deb ${DEB2}: ${DEB}

.PHONY: download
download: ${SRCTAR}
${SRCTAR}:
	rm -rf ${SRCDIR} ${SRCTAR} pacman-git
	git clone --depth=1 --branch=v${PACMANVER} git://projects.archlinux.org/pacman.git pacman-git
	(cd pacman-git && git archive --prefix=${SRCDIR}/ --format=tar v${PACMANVER}) | gzip > ${SRCTAR}.tmp
	mv ${SRCTAR}.tmp ${SRCTAR}
	rm -rf pacman-git

distclean: clean

.PHONY: clean
clean:
	rm -rf ${SRCDIR} ${SRCDIR}.tmp *_${ARCH}.deb *.changes *.dsc *.buildinfo
	find . -name '*~' -exec rm {} ';'

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}
