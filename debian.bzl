load("@bazel_tools//tools/build_defs/repo:utils.bzl", "workspace_and_buildfile")

def __make_output_name(name, url):
    return name

def _download_debian(ctx, url):
    loaded = ctx.download(
        url = url,
        output = __make_output_name(ctx.name, url),
        sha256 = ctx.attr.sha256,
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
    all_urls = []
    if ctx.attr.urls:
        all_urls = ctx.attr.urls
    if ctx.attr.url:
        all_urls = [ctx.attr.url] + all_urls
    return all_urls

def _assert_preconditions(ctx):
    if not ctx.attr.url and not ctx.attr.urls:
        fail("At least one of url and urls must be provided")

    for url in _get_urls_to_load(ctx):
        if not url.endswith(".deb"):
            fail("Url must point to a .deb file", "url: {}".format(url))

def _debian_archive_impl(ctx):
    _assert_preconditions(ctx)
    for url in _get_urls_to_load(ctx):
        _download_debian(ctx, url)
        _extract_debian(ctx, url)

    _cleanup_download_dir(ctx)
    _setup_bazel_files(ctx)

debian_archive = repository_rule(
    attrs = {
        "sha256": attr.string(default = ""),
        "url": attr.string(default = ""),
        "urls": attr.string_list(default = []),
        "build_file": attr.label(allow_single_file = True),
        "build_file_content": attr.string(default = ""),
        "workspace_file": attr.label(allow_single_file = True),
        "workspace_file_content": attr.string(default = ""),
    },
    local = False,
    implementation = _debian_archive_impl,
)
