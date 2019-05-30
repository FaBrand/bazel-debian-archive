_DEFAULT_BUILD_FILE_TEMPLATE = """
filegroup(
    name = "files",
    srcs = glob(["**/*"]),
    visibility = ["//visibility:public"],
)

cc_library(
    name = "lib",
    srcs = glob(["usr/lib/**/*.a", "usr/lib/**/*.so"]),
    hdrs = glob(["usr/include/**/*"]),
    includes = ["usr/include"],
    visibility = ["//visibility:public"],
    linkstatic = True,
)
"""

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
    if ctx.attr.build_file:
        ctx.symlink(ctx.attr.build_file, "BUILD.bazel")
    else:
        build_file_content = _DEFAULT_BUILD_FILE_TEMPLATE.format(name = ctx.name)
        ctx.file("BUILD.bazel", build_file_content)

    if ctx.attr.workspace_file:
        ctx.symlink(ctx.path(ctx.attr.workspace_file), "WORKSPACE")
    else:
        ctx.file("WORKSPACE", "")

def _get_urls_to_load(ctx):
    all_urls = []
    if ctx.attr.urls:
        all_urls = ctx.attr.urls
    if ctx.attr.url:
        all_urls = [ctx.attr.url] + all_urls
    return all_urls

def _debian_archive_impl(ctx):
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
        "workspace_file": attr.label(allow_single_file = True),
    },
    local = False,
    implementation = _debian_archive_impl,
)
