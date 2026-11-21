# Outcrop

## Install

Ubuntu Server 22.04 / 24.04 LTS (amd64, Perl 5.34 or later).

```sh
sudo apt update
sudo apt install perl carton build-essential git curl ca-certificates util-linux mount xfsprogs
```

[Install Syft and Grype](docs/operations.md#syft-and-grype), then install Outcrop.

```sh
sudo sh -eu <<'SH'
umask 0022
git clone https://github.com/viasnake/outcrop.git /opt/outcrop
cd /opt/outcrop
PERL_CARTON_MIRROR=https://cpan.metacpan.org /usr/bin/carton install --deployment --without develop
chown -R root:root /opt/outcrop
chmod -R go-w /opt/outcrop
SH
```

## Start

```sh
sudo sh -eu <<'SH'
getent passwd outcrop >/dev/null ||
  useradd --system --user-group --home-dir /nonexistent --shell /usr/sbin/nologin outcrop
for mode in worker web; do
  sed -e 's|^WorkingDirectory=.*|WorkingDirectory=/opt/outcrop|' \
      -e "s|^ExecStart=.*|ExecStart=/usr/bin/carton exec /usr/bin/perl script/outcrop $mode|" \
      "/opt/outcrop/systemd/outcrop-$mode.service" > "/etc/systemd/system/outcrop-$mode.service"
done
systemctl daemon-reload
systemctl enable --now outcrop-worker.service outcrop-web.service
SH
```

## Use

Open [http://127.0.0.1:8080](http://127.0.0.1:8080). Use SSH port forwarding to connect from another machine. The web interface has no authentication.

```sh
ssh -N -L 8080:127.0.0.1:8080 user@scanner-host
```

To scan a clone, attach an independent copy (one ext4 or XFS disk) to a dedicated VM with automount disabled and select it in the interface. Confirm it is unmounted before disconnecting it.

[Operations guide (updates and CPAN)](docs/operations.md) · [Contributing](CONTRIBUTING.md) · [Apache-2.0](LICENSE)
