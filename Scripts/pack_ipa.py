#!/usr/bin/env python3
"""把 xcarchive 里的 .app 打包成 IPA。

为什么不用 Info-ZIP 的 zip 命令：
  国内签名工具（全能签等）多用 SSZipArchive / minizip 1.x 解析，
  它对 Info-ZIP 写出的附加字段、目录条目、数据描述符比较敏感，
  历史上出现过「failed to open zip file / 未得到主包」的报错。
  这里完全自己写 zip 结构：
    - 不写任何 extra field
    - 可选不写目录条目（只写文件，解压器自动建目录）
    - 固定 DOS 时间戳，保证可复现
    - 保留 Unix 权限位（二进制 755）
用法：
  pack_ipa.py <ZiWeiDaily.app 路径> <输出 ipa 路径> [--deflate|--store] [--no-dirs]
"""

import os
import stat
import sys
import zipfile

FIXED_TIME = (2026, 11, 8, 12, 0, 0)


def collect(app_path):
    """返回 [(arcname, srcpath, is_dir)]，顺序稳定：目录在前，文件按路径排序。"""
    app_name = os.path.basename(app_path.rstrip("/"))
    items = []
    items.append((f"Payload/{app_name}/", app_path, True))
    for root, dirs, files in os.walk(app_path):
        dirs.sort()
        for name in sorted(dirs):
            src = os.path.join(root, name)
            rel = os.path.relpath(src, app_path)
            items.append((f"Payload/{app_name}/{rel}/", src, True))
        for name in sorted(files):
            src = os.path.join(root, name)
            rel = os.path.relpath(src, app_path)
            items.append((f"Payload/{app_name}/{rel}", src, False))
    return items


def build(app_path, out_path, compress, with_dirs):
    items = collect(app_path)
    method = zipfile.ZIP_DEFLATED if compress else zipfile.ZIP_STORED
    with zipfile.ZipFile(out_path, "w", compression=method,
                         allowZip64=False, compresslevel=9) as zf:
        for arcname, src, is_dir in items:
            if is_dir and not with_dirs:
                continue
            st = os.stat(src)
            info = zipfile.ZipInfo(arcname, date_time=FIXED_TIME)
            info.create_system = 3  # Unix，让 external_attr 里的权限位有意义
            mode = st.st_mode & 0o777
            if is_dir:
                info.external_attr = (stat.S_IFDIR | mode) << 16 | 0x10
                info.compress_type = zipfile.ZIP_STORED
                zf.writestr(info, b"")
            else:
                info.external_attr = (stat.S_IFREG | mode) << 16
                info.compress_type = method
                with open(src, "rb") as fh:
                    zf.writestr(info, fh.read())
    return out_path


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    app_path, out_path = sys.argv[1], sys.argv[2]
    flags = sys.argv[3:]
    compress = "--store" not in flags
    with_dirs = "--no-dirs" not in flags
    build(app_path, out_path, compress, with_dirs)
    size = os.path.getsize(out_path)
    print(f"{out_path}  {size:,} bytes  ({'deflate' if compress else 'store'}"
          f"{', no dir entries' if not with_dirs else ''})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
