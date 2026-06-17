#!/usr/bin/env bash
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
# Deterministic RestructuredText -> AsciiDoc conversion for the Flume website.
#
# Converts every page under source/sphinx into the Antora page tree at
# src/site/antora/modules/ROOT/pages, using pandoc for the heavy lifting plus
# a few scripted fixups for things pandoc cannot know about (Antora xrefs and
# the ASF license header). Safe to re-run: the destination pages dir is wiped
# and regenerated from the RST sources each time.
#
# Requirements: pandoc (>= 3.x), bash.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/source/sphinx"
DEST="$ROOT/src/site/antora/modules/ROOT/pages"
IMG_SRC="$SRC/images"
IMG_DEST="$ROOT/src/site/antora/modules/ROOT/images"

# AsciiDoc block-comment license header (pandoc drops the RST comment header).
LICENSE_HEADER=$'////\n    Licensed to the Apache Software Foundation (ASF) under one or more\n    contributor license agreements.  See the NOTICE file distributed with\n    this work for additional information regarding copyright ownership.\n    The ASF licenses this file to You under the Apache License, Version 2.0\n    (the "License"); you may not use this file except in compliance with\n    the License.  You may obtain a copy of the License at\n\n         http://www.apache.org/licenses/LICENSE-2.0\n\n    Unless required by applicable law or agreed to in writing, software\n    distributed under the License is distributed on an "AS IS" BASIS,\n    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\n    See the License for the specific language governing permissions and\n    limitations under the License.\n////\n'

echo "Cleaning $DEST"
rm -rf "$DEST"
mkdir -p "$DEST"

# Convert every .rst page. Sphinx-only sources (conf.py, contents.rsx, the
# _templates / _themes dirs) are intentionally skipped.
while IFS= read -r -d '' rst; do
  rel="${rst#"$SRC"/}"            # e.g. releases/1.11.0.rst
  adoc="${rel%.rst}.adoc"         # e.g. releases/1.11.0.adoc
  out="$DEST/$adoc"
  mkdir -p "$(dirname "$out")"

  # 1. pandoc: RST -> AsciiDoc. `-s` makes the top section title a level-0
  #    document title (`= Title`), which is what Antora wants per page.
  body="$(pandoc -f rst -t asciidoc --wrap=preserve -s "$rst")"

  # 2. Prepend the ASF license header.
  printf '%s\n%s\n' "$LICENSE_HEADER" "$body" > "$out"
  echo "  $rel -> ${out#"$ROOT"/}"
done < <(find "$SRC" -type f -name '*.rst' -print0)

# Images: copy the Sphinx image dir into the module images dir.
if [ -d "$IMG_SRC" ]; then
  echo "Copying images $IMG_SRC -> $IMG_DEST"
  mkdir -p "$IMG_DEST"
  cp -a "$IMG_SRC/." "$IMG_DEST/"
fi

# 3. Rewrite relative `.html` links into Antora `xref:` macros, but only for
#    pages that actually exist (needs the full page set, hence a separate pass).
python3 "$ROOT/tools/fix_xrefs.py" "$DEST"

echo "Done."