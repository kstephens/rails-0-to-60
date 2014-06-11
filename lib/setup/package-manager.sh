notes <<EOF
This demo requires a few newer system packages than maybe available by default.

These can be found from Debian backports.
EOF

debian6 comment Add squeeze-backports.
debian6 ok "sudo cp lib/sources.list.d/$debian_name-backports.list /etc/apt/sources.list.d/"
debian6 ok "sudo apt-get update"

ubuntu1204 comment Add Ubuntu 12.04 precise-backports
ubuntu1204 "sudo cp lib/sources.list.d/$debian_name-backports.list /etc/apt/sources.list.d/"
ubuntu1204 "sudo apt-get update"

osx comment Check for macports.
osx 'which port'

