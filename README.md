# Mogura

Inspect a Linux host or an attached ext4 or XFS disk with Syft and Grype. Install the distribution with Perl 5.34 or later and start the server as your regular user.

```sh
# From a locally built distribution
cpanm ./Mogura-0.01.tar.gz
mogura server
```

After publication, install with `cpanm Mogura`. Open [the web interface](http://127.0.0.1:8080), [connect a scanner](docs/operations.md), and select a disk under its scanner name. Open History to search results, edit tags and notes, or download the original files.

[Build and test](CONTRIBUTING.md) · [Apache-2.0](LICENSE)
