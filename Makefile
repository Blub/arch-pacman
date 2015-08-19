RELEASE=4.2.1

PACKAGE=arch-pacman
PACMANVER=4.2.1
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
	echo "git clone git://git.proxmox.com/git/arch-pacman.git\\ngit checkout ${GITVERSION}" >  ${SRCDIR}/debian/SOURCE
	cd ${SRCDIR}; DEB_BUILD_OPTIONS=nocheck dpkg-buildpackage -rfakeroot -b -us -uc
	lintian ${DEBS}

.PHONY: deb
deb ${DEB2}: ${DEB}

.PHONY: download
download ${SRCTAR}:
	rm -rf ${SRCDIR} ${SRCTAR} pacman-git
	git clone --depth=1 --branch=v${PACMANVER} git://projects.archlinux.org/pacman.git pacman-git
	(cd pacman-git && git archive --prefix=${SRCDIR}/ --format=tar v${PACMANVER}) | gzip > ${SRCTAR}.tmp
	mv ${SRCTAR}.tmp ${SRCTAR}
	rm -rf pacman-git

# FIXME:
#.PHONY: upload
#upload: ${DEBS}
#	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o rw 
#	mkdir -p /pve/${RELEASE}/extra
#	rm -f /pve/${RELEASE}/extra/${PACKAGE}_*.deb
#	rm -f /pve/${RELEASE}/extra/${PACKAGE}-dev_*.deb
#	rm -f /pve/${RELEASE}/extra/${PACKAGE}-dbg_*.deb
#	rm -f /pve/${RELEASE}/extra/Packages*
#	cp ${DEBS} /pve/${RELEASE}/extra
#	cd /pve/${RELEASE}/extra; dpkg-scanpackages . /dev/null > Packages; gzip -9c Packages > Packages.gz
#	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o ro

distclean: clean

.PHONY: clean
clean:
	rm -rf ${SRCDIR} ${SRCDIR}.tmp *_${ARCH}.deb *.changes *.dsc 
	find . -name '*~' -exec rm {} ';'

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}
