dnf update -y
dnf install -y epel-release
dnf update -y
dnf install -yq vim jq tmux curl wget
dnf install -yq mariadb-server mariadb-backup && \
    systemctl enable mariadb && \
    systemctl restart mariadb

