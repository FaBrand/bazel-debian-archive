load("@bazel_tools//tools/build_defs/repo:utils.bzl", "workspace_and_buildfile")

def __make_output_name(name, url):
    return name

def _download_debian(ctx, url, sha):
    loaded = ctx.download(
        url = url,
        output = __make_output_name(ctx.name, url),
        sha256 = sha,
    )

    if not loaded:
        fail("Download of {} failed".format(ctx.attr.url))

def _extract_debian(ctx, url):
    tool = ctx.which("dpkg-deb")
    if not tool:
        fail("dpkg-deb not found")

    extraction_succeeded = ctx.execute([tool, "-X", __make_output_name(ctx.name, url), "./"])
    if not extraction_succeeded:
        fail("Extraction failed")

def _cleanup_download_dir(ctx):
    # Not yet in bazel 0.25.2
    # ctx.delete("extracted/usr/share/")
    cleanup = ctx.execute(["rm", "-rf", "usr/share"])
    cleanup = cleanup and ctx.execute(["rm", "-f", ctx.name])
    if not cleanup:
        fail("Cleanup failed")

def _setup_bazel_files(ctx):
    workspace_and_buildfile(ctx)

def _get_urls_to_load(ctx):
    all_urls = {}
    if ctx.attr.urls:
        all_urls.update(ctx.attr.urls)
    if ctx.attr.url:
        all_urls.update({ctx.attr.url: ctx.attr.sha256})
        all_urls.update(all_urls)
    return all_urls

def _assert_preconditions(ctx):
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

    _cleanup_download_dir(ctx)
    _setup_bazel_files(ctx)

debian_archive = repository_rule(
    attrs = {
        "sha256": attr.string(default = ""),
        "url": attr.string(default = ""),
        "urls": attr.string_dict(default = {}),
        "build_file": attr.label(allow_single_file = True),
        "build_file_content": attr.string(default = ""),
        "workspace_file": attr.label(allow_single_file = True),
        "workspace_file_content": attr.string(default = ""),
    },
    local = False,
    implementation = _debian_archive_impl,
)
