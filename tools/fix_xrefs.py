#!/usr/bin/env python3
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Rewrites the relative `.html` links that pandoc emits as `link:...[]` into
# Antora `xref:...adoc[]` macros, but ONLY when the target page actually exists
# in the generated page tree. Links that point at non-migrated artifacts (the
# frozen per-version `content/<ver>/...` doc bundles and Javadoc `apidocs/`)
# resolve to nothing, so they are left as plain `link:` for a human to decide
# how to host. The relative path text is preserved verbatim, so Antora resolves
# each xref relative to the current page exactly as the original link did.

import os
import re
import sys

PAGES = sys.argv[1] if len(sys.argv) > 1 else "src/site/antora/modules/ROOT/pages"

# link:<path>.html[  or  link:<path>.html#anchor[   (relative links only;
# pandoc renders absolute links as bare URLs without the `link:` prefix).
LINK = re.compile(r"link:([A-Za-z0-9_./-]+?)\.html(#[^\[\]]*)?\[")

# Block/inline image macros: pandoc keeps the RST `images/` directory prefix,
# but Antora already resolves image targets against the module `images/` dir,
# so the prefix must be dropped (`image::images/x.png[]` -> `image::x.png[]`).
IMAGE = re.compile(r"(image::?)images/")

# Set of page ids that exist, as paths relative to the pages root.
existing = set()
for dirpath, _dirs, files in os.walk(PAGES):
    for name in files:
        if name.endswith(".adoc"):
            rel = os.path.relpath(os.path.join(dirpath, name), PAGES)
            existing.add(rel)

converted = 0
skipped = 0

for dirpath, _dirs, files in os.walk(PAGES):
    for name in files:
        if not name.endswith(".adoc"):
            continue
        path = os.path.join(dirpath, name)
        page_dir = os.path.relpath(dirpath, PAGES)

        def repl(m):
            global converted, skipped
            target, anchor = m.group(1), m.group(2) or ""
            # The original `.html` link is relative to the current page's
            # directory. Antora, however, resolves a bare xref resource path
            # relative to the pages root (only `./` and `../` are page-relative),
            # so emit the normalized pages-root-relative page id.
            page_id = os.path.normpath(os.path.join(page_dir, target)).replace(os.sep, "/")
            if page_id + ".adoc" in existing:
                converted += 1
                return f"xref:{page_id}.adoc{anchor}["
            skipped += 1
            return m.group(0)

        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        new = IMAGE.sub(r"\1", LINK.sub(repl, text))
        if new != text:
            with open(path, "w", encoding="utf-8") as fh:
                fh.write(new)

print(f"xref rewrite: {converted} converted, {skipped} left as link: (no target page)")