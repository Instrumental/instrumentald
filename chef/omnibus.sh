#!/bin/sh
if ! which chef-solo; then
    if [ -e "/etc/gentoo-release" ]; then
        mkdir -p /usr/portage
        emerge --sync
        emerge --oneshot portage
        emerge -C perl-core/Module-Metadata
        emerge -C perl-core/Parse-CPAN-Meta
        emerge -C lang-dev/perl
        emerge perl
        emerge layman
        echo "source /var/lib/layman/make.conf" >> /etc/portage/make.conf
        echo "conf_type : make.conf" >> /etc/layman/layman.cfg
        layman -o https://raw.github.com/lxmx/gentoo-overlay/master/overlay.xml -f -a lxmx
        echo "app-admin/chef-omnibus ~amd64" >> /etc/portage/package.keywords
        emerge app-admin/chef-omnibus
    else
        if which curl; then
            curl -L https://www.chef.io/chef/install.sh | bash
        elif which wget; then
            wget -qO- https://www.chef.io/chef/install.sh | bash
        else
            echo "Couldn't find curl or wget"
            exit 1
        fi
    fi
fi
