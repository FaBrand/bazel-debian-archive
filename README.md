# Debian archive repository rules
This rule can be used to utilize files that are available as a debian archive.
To unzip the files, dpkg must be available on the system.
As debian archives typically don't contain BUILD or WORKSPACE files,
the attribute `build_file(_content)` is mandatory.

### Example usage:

```python
git_repository(
    name = "debian_repository_rules",
    branch = "master",
    remote = "https://github.com/fabrand/debian_repository_rules",
)

load("@debian_repository_rules//:debian.bzl", "debian_archive")

debian_archive(
    name = "python3",
    build_file = "python3.BUILD",
    urls = {
        "http://launchpadlibrarian.net/394585029/python3.7-minimal_3.7.1-1~18.04_amd64.deb": "4ddc47a919f35d938e526f6e29722e6f50eaf56d8fc8b80d6be4cdd9b8f26e54",
        "http://launchpadlibrarian.net/394585020/libpython3.7-minimal_3.7.1-1~18.04_amd64.deb": "38a61fb89e87c9fc904a1693809921bed0735e2e467a8daaa9bd5381e3e3b848",
        "http://launchpadlibrarian.net/341324234/libpython3.7-stdlib_3.7.0~a2-1_amd64.deb": "c1bb1baeb1827354c18eb4619fbc08cfe32b5ac2ea2449ae7dccb041d9733c16",
    },
)
```

Or:

```python
debian_archive(
    name = "python3",
    build_file = "python3.BUILD",
    url = "http://launchpadlibrarian.net/394585029/python3.7-minimal_3.7.1-1~18.04_amd64.deb",
    sha256 = "4ddc47a919f35d938e526f6e29722e6f50eaf56d8fc8b80d6be4cdd9b8f26e54",
)
```
