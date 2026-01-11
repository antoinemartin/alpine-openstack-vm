#!/bin/sh
# cSpell: words iface pwauth zshrc ohmyzsh autosuggestions p10k powerlevel10k atsg acpid chronyd crond termencoding
_step_counter=0
step() {
	_step_counter=$(( _step_counter + 1 ))
	printf '\n\033[1;36m%d) %s\033[0m\n' $_step_counter "$@" >&2  # bold cyan
}


CLOUD_CONFIG_FILE=${1:-cloud-config.yaml}

step 'Set up timezone'
setup-timezone -z Europe/Paris

step 'Set up keymap'
setup-keymap fr fr-azerty

step 'Set up networking'
cat > /etc/network/interfaces <<-EOF
	auto lo
	iface lo inet loopback

	auto eth0
	iface eth0 inet dhcp
EOF

# FIXME: remove root and alpine password
step "Set cloud configuration (with $CLOUD_CONFIG_FILE)"
sed -e '/disable_root:/ s/true/false/' \
	-e '/ssh_pwauth:/ s/0/no/' \
    -e '/name: alpine/a \    passwd: "*"' \
    -e '/lock_passwd:/ s/True/False/' \
    -e '/shell:/ s#/bin/ash#/bin/zsh#' \
    -i /etc/cloud/cloud.cfg

# Copy specific configuration
cp "$CLOUD_CONFIG_FILE" /etc/cloud/cloud.cfg.d/90_user.cfg

step 'Allow only key based ssh login'
sed -e '/PermitRootLogin yes/d' \
    -e 's/^#PasswordAuthentication yes/PasswordAuthentication no/' \
    -e 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' \
    -i /etc/ssh/sshd_config

# Terraform and github actions need ssh-rsa as accepted algorithm
# The ssh client needs to be updated (see https://www.openssh.com/txt/release-8.8)
echo "PubkeyAcceptedKeyTypes=+ssh-rsa" >> /etc/ssh/sshd_config

step 'Remove password for users'
usermod -p '*' root

step 'Adjust rc.conf'
sed -Ei \
	-e 's/^[# ](rc_depend_strict)=.*/\1=NO/' \
	-e 's/^[# ](rc_logger)=.*/\1=YES/' \
	-e 's/^[# ](unicode)=.*/\1=YES/' \
	/etc/rc.conf

step 'Enabling zsh'
# Install ZSH pimp tools
P10K_DIR="/usr/share/oh-my-zsh/custom/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
    LATEST_P10K_VERSION=$(wget -qO- https://api.github.com/repos/romkatv/powerlevel10k/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
    wget -q https://github.com/romkatv/powerlevel10k/archive/refs/tags/v$LATEST_P10K_VERSION.tar.gz -O /tmp/p10k.tar.gz
    tar xzf /tmp/p10k.tar.gz -C /tmp
    mv /tmp/powerlevel10k-$LATEST_P10K_VERSION "$P10K_DIR"
    rm /tmp/p10k.tar.gz
fi
ATSG_DIR="/usr/share/oh-my-zsh/custom/plugins/zsh-autosuggestions"
if [ ! -d "$ATSG_DIR" ]; then
    LATEST_ATSG_VERSION="0.7.1"
    wget -q https://github.com/zsh-users/zsh-autosuggestions/archive/refs/tags/v$LATEST_ATSG_VERSION.tar.gz -O /tmp/atsg.tar.gz
    tar xzf /tmp/atsg.tar.gz -C /tmp
    mv /tmp/zsh-autosuggestions-$LATEST_ATSG_VERSION "$ATSG_DIR"
    rm /tmp/atsg.tar.gz
fi

sed -e 's#^export ZSH=.*#export ZSH=/usr/share/oh-my-zsh#g' \
    -e '/^plugins=/ s#.*#plugins=(git zsh-autosuggestions)#' \
    -e '/^ZSH_THEME=/ s#.*#ZSH_THEME="powerlevel10k/powerlevel10k"#' \
    -e '$a[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' \
    -i /usr/share/oh-my-zsh/templates/zshrc.zsh-template

install -m 700 -o root -g root /usr/share/oh-my-zsh/templates/zshrc.zsh-template /root/.zshrc
install -m 740 -o root -g root p10k.zsh /root/.p10k.zsh

sed -ie '/^root:/ s#:/bin/.*$#:/bin/zsh#' /etc/passwd

step 'Enabling oh-my-zsh for all users'
mkdir -p /etc/skel
install -m 700 -o root -g root /usr/share/oh-my-zsh/templates/zshrc.zsh-template /etc/skel/.zshrc
install --directory -o root -g root -m 0700 /etc/skel/.ssh
install -m 740 -o root -g root p10k.zsh /etc/skel/.p10k.zsh


# see https://gitlab.alpinelinux.org/alpine/aports/-/issues/88²61
step 'Enable cloud-init configuration via NoCloud iso image'

echo "iso9660" >> /etc/filesystems

step 'Enable services'
rc-update add acpid default
rc-update add chronyd default
rc-update add crond default
rc-update add networking boot
rc-update add termencoding boot
rc-update add sshd default
rc-update add cloud-init-ds-identify default
rc-update add cloud-init-local default
rc-update add cloud-init default
rc-update add cloud-config default
rc-update add cloud-final default
