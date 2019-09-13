load("@bazel_tools//tools/build_defs/repo:utils.bzl", "workspace_and_buildfile")

def __make_output_name(name, url):
    """Construct a unique name from the rule name and the url"""
    combined = name + url
    combined = combined.replace(':','/')
    combined = combined.replace('.','/')
    return combined

def _download_debian(ctx, url, sha):
    """Download a single debian file"""
    loaded = ctx.download(
        url = url,
        output = __make_output_name(ctx.name, url),
        sha256 = sha,
    )

    if not loaded:
        fail("Download of {} failed".format(ctx.attr.url))

def _extract_debian(ctx, url):
    """Extract the debian package using the system 'dpkg-deb' tool"""
    tool = ctx.which("dpkg-deb")
    if not tool:
        fail("dpkg-deb not found")

    extraction_succeeded = ctx.execute([tool, "-X", __make_output_name(ctx.name, url), "./"])

    if not extraction_succeeded:
        fail("Extraction failed")

def _setup_bazel_files(ctx):
    workspace_and_buildfile(ctx)

def _get_urls_to_load(ctx):
    """Build a dictionary of {url: sha} items that represent all urls to be downloaded"""
    all_urls = {}
    if ctx.attr.urls:
        all_urls.update(ctx.attr.urls)
    if ctx.attr.url:
        all_urls.update({ctx.attr.url: ctx.attr.sha256})
        all_urls.update(all_urls)
    return all_urls

def _assert_preconditions(ctx):
    """Check constraints on attributes that aren't enforced by bazel"""
    if not ctx.attr.build_file and not ctx.attr.build_file_content:
        fail("Please provide a build_file or build_file_content attribute")

    if not ctx.attr.url and not ctx.attr.urls:
        fail("At least one of url and urls must be provided")

    for url in _get_urls_to_load(ctx).keys():
        if not url.endswith(".deb"):
            fail("Url must point to a .deb file", "url: {}".format(url))

    if not ctx.attr.url and ctx.attr.urls and ctx.attr.sha256:
        fail("sha cannot be provided with attribute 'urls'", "sha256")

def _debian_archive_impl(ctx):
    _assert_preconditions(ctx)
    for url, sha in _get_urls_to_load(ctx).items():
        _download_debian(ctx, url, sha)
        _extract_debian(ctx, url)

    _setup_bazel_files(ctx)

debian_archive = repository_rule(
    attrs = {
        "sha256": attr.string(
            doc = """
            This sha will be used for the url attribute if provided
            """,
            default = "",
        ),
        "url": attr.string(
            default = "",
            doc = """
            Provide a link to a debian file.
            e.g. a package stored in a debian repository
            """,
        ),
        "urls": attr.string_dict(
            default = {},
            doc = """
            Multiple urls aka debian packages can be provided in the form of "url": "sha256".
            if the sha is not desired, set the item value to an empty string.
            """,
        ),
        "build_file": attr.label(
            allow_single_file = True,
            doc = """
            The build file that shall be used to describe the package content
            """,
        ),
        "build_file_content": attr.string(
            default = "",
            doc = """
            The string that shall be used to create the build file that shall be used to describe the package content
            """,
        ),
        "workspace_file": attr.label(
            allow_single_file = True,
            doc = """
            The workspace file that shall be used to describe the package content
            """,
        ),
        "workspace_file_content": attr.string(
            default = "",
            doc = """
            The string that shall be used to create the workspace file that shall be used to describe the package content
            """,
        ),
    },
    doc = """
    This rule can be used to utilize files that are available as a debian archive.
    To unzip the files, dpkg must be available on the system.
    As debian archives typically don't contain BUILD or WORKSPACE files,
    the attribute build_file(_content) is mandatory.

    Example usage:

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

    Or:

        debian_archive(
            name = "python3",
            build_file = "python3.BUILD",
            url = "http://launchpadlibrarian.net/394585029/python3.7-minimal_3.7.1-1~18.04_amd64.deb",
            sha256 = "4ddc47a919f35d938e526f6e29722e6f50eaf56d8fc8b80d6be4cdd9b8f26e54",
        )
    """,
    local = False,
    implementation = _debian_archive_impl,
)
