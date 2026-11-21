# Running Mogura

## Server

Run `mogura server` as the account that owns the results. It creates its SQLite database under `$XDG_STATE_HOME/mogura` (default `~/.local/state/mogura`). Use the same `--state DIR` on the server and its token administration commands when choosing another location. Back up this directory with the server stopped. Raw artifacts are immutable. Search indexes can be rebuilt from the scan page.

The default listener is `http://127.0.0.1:8080`. For remote browser access, forward that port over SSH.

```sh
ssh -N -L 8080:127.0.0.1:8080 user@server-host
```

For remote scanners, terminate HTTPS at a reverse proxy on the server host and proxy `/api/` to loopback. Preserve Authorization, Content-Length and X-Content-SHA256, disable request buffering for uploads, and allow PUT bodies up to 4 GiB. Keep the UI on loopback or require user authentication at the proxy on **every** other path, including downloads and static files. Use a certificate trusted by the scanner host. For colocated processes, use `--server http://127.0.0.1:8080`.

## Register a scanner

As the server owner, choose a stable, unique name and write its credential to a new file.

```sh
mogura register lab-a --token-file ./lab-a.token
```

Transfer the file privately to the scanner host. Install it there as root with mode 0600 at `/etc/mogura/scanner-token`. To rotate a credential for the same scanner ID, run `mogura issue lab-a --token-file ./lab-a-new.token` and install the replacement. To disable a credential, run `mogura revoke lab-a`. Revocation also prevents new job submissions for that scanner.

## Install and start the scanner

Use a dedicated Linux VM with automount disabled. Attach only independent copies. Do not attach production volumes. These examples target Ubuntu Server 22.04 or 24.04 on amd64.

```sh
sudo apt install perl cpanminus build-essential libssl-dev curl ca-certificates util-linux mount xfsprogs
sudo install -d -m 0755 -o root -g root /opt/mogura-perl /etc/mogura
sudo install -m 0600 -o root -g root ./lab-a.token /etc/mogura/scanner-token
sudo /usr/bin/cpanm --local-lib-contained /opt/mogura-perl --exclude-vendor ./Mogura-0.01.tar.gz
```

Install from a trusted archive. Use the system Perl and a dedicated root-owned prefix whose ancestors, modules, native libraries and executables deny group and other writes. Keep the prefix free of symlinks. Install the tools below, then run the foreground scanner.

```sh
sudo /opt/mogura-perl/bin/mogura scanner --server https://mogura.example.com --token-file /etc/mogura/scanner-token
```

The default state and mount roots are `/var/lib/mogura-scanner` and `/run/mogura-scanner`. Choose private, root-owned paths with `--state` and `--runtime`. Keep these paths, the scanner identity and the server address associated across restarts. Set `--syft` and `--grype` to trusted absolute executable paths when needed.

## Syft and Grype

On Ubuntu amd64, install both tools in `/usr/local/bin` before starting the scanner.

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

## Capacity and recovery

The default is two concurrent scans and an 8 GiB spool budget. Use `--jobs N` (1–64) and `--spool-limit BYTES` to change them. The scanner divides available space between output files and scan slots. Allow extra space for each slot's Grype database. A tool that reaches its per-file limit fails the scan. Provision the server separately for retained artifacts, incoming uploads and search indexes.

Select **Cancel scan** on the scan page to remove a queued job or stop a running scan. An offline scanner receives the request when it reconnects. Check the mount status before disconnecting a disk.

Stop either process with SIGTERM or Ctrl-C. Keep the scanner spool during an outage. A restart reconciles started jobs against local locks and mountinfo. Unconfirmed deliveries retry after reconnection. If a scan is interrupted, inspect its status before submitting another job.

When the UI reports cleanup is required, inspect the scanner's mount namespace with `findmnt` and check for surviving scanner processes. Verify the disk and the mount source before performing a normal unmount of a confirmed residual mount. Keep the disk attached while its state is unknown. An offline scanner's last reported mount state is historical.

## Scan coverage

Mogura inspects the selected root filesystem. It excludes separate mounts and the root-relative log, crash, and coredump directories. Read warnings about uninspected paths even when a scan completes. Reading the live host does not create a point-in-time snapshot.
