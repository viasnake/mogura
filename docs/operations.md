# Operations

## Syft and Grype

On Ubuntu amd64, install both tools in `/usr/local/bin` before starting Outcrop.

```sh
(
  set -eu
  cd "$(mktemp -d)"

  curl -fLO https://github.com/anchore/syft/releases/download/v1.55.0/syft_1.55.0_linux_amd64.tar.gz
  curl -fLO https://github.com/anchore/syft/releases/download/v1.55.0/syft_1.55.0_checksums.txt
  sha256sum --check --ignore-missing syft_1.55.0_checksums.txt
  tar -xzf syft_1.55.0_linux_amd64.tar.gz syft
  sudo install -o root -g root -m 0755 syft /usr/local/bin/syft

  curl -fLO https://github.com/anchore/grype/releases/download/v0.121.0/grype_0.121.0_linux_amd64.tar.gz
  curl -fLO https://github.com/anchore/grype/releases/download/v0.121.0/grype_0.121.0_checksums.txt
  sha256sum --check --ignore-missing grype_0.121.0_checksums.txt
  tar -xzf grype_0.121.0_linux_amd64.tar.gz grype
  sudo install -o root -g root -m 0755 grype /usr/local/bin/grype
)
```

## Install from a CPAN distribution archive

[Build the archive](../CONTRIBUTING.md#build-a-distribution) or use an existing copy. Run the following from the directory containing the archive.

```sh
sudo apt update
sudo apt install perl cpanminus build-essential curl ca-certificates util-linux mount xfsprogs
sudo cpanm --local-lib-contained /opt/outcrop-perl --exclude-vendor ./App-Outcrop-0.01.tar.gz
sudo chown -R root:root /opt/outcrop-perl
sudo chmod -R go-w /opt/outcrop-perl
/opt/outcrop-perl/bin/outcrop --version
```

Worker requires root ownership and disallows group and other writes for the installation, its parent directories, and the scan executables. The CPAN installation directory must be free of symbolic links.

```sh
sudo sh -eu <<'SH'
getent passwd outcrop >/dev/null ||
  useradd --system --user-group --home-dir /nonexistent --shell /usr/sbin/nologin outcrop
units=/opt/outcrop-perl/lib/perl5/App/Outcrop/share/systemd
for mode in worker web; do
  sed "s|^ExecStart=.*|ExecStart=/opt/outcrop-perl/bin/outcrop $mode|" \
      "$units/outcrop-$mode.service" > "/etc/systemd/system/outcrop-$mode.service"
done
systemctl daemon-reload
systemctl enable --now outcrop-worker.service outcrop-web.service
SH
```

## Update

Wait for running scans to finish, then stop both services. A restart interrupts running scans, attempts to unmount their filesystems, and resumes queued requests. Re-submit interrupted scans if needed.

```sh
sudo systemctl stop outcrop-web.service outcrop-worker.service
```

For a GitHub installation, update the checkout and apply the [startup instructions](../README.md#start) to refresh the units and start the services.

```sh
sudo sh -eu <<'SH'
umask 0022
cd /opt/outcrop
git pull --ff-only
PERL_CARTON_MIRROR=https://cpan.metacpan.org /usr/bin/carton install --deployment --without develop
chown -R root:root /opt/outcrop
chmod -R go-w /opt/outcrop
SH
```

For a CPAN installation, repeat the archive installation and startup with the new archive. When switching installation methods, update any systemd drop-ins that override the previous paths.

```sh
systemctl --no-pager --full status outcrop-worker.service outcrop-web.service
sudo journalctl -u outcrop-worker.service -u outcrop-web.service -n 50
```

## Settings

For LAN access, run `sudo systemctl edit outcrop-web.service` and set the listener below. Outcrop has no authentication. Limit connections to trusted machines with a firewall or equivalent controls.

```ini
[Service]
Environment=OUTCROP_LISTEN=http://0.0.0.0:8080
```

Worker runs two concurrent scans by default. To set the limit (1–64), run `sudo systemctl edit outcrop-worker.service` after active scans finish.

```ini
[Service]
Environment=OUTCROP_WORKER_JOBS=4
```

Restart the service whose settings you changed.

Persistent state, including results, the queue, annotations, and Grype databases, is stored in `/var/lib/outcrop`.

## Scan coverage

Outcrop scans the selected filesystem without following separate mounts such as NFS, EFS, or a separate `/usr` or `/var`. The root-relative `/var/log`, `/var/crash`, and `/var/lib/systemd/coredump` are excluded. Check warnings for uninspected paths even when a scan completes.
