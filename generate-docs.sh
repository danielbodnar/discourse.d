#!/usr/bin/env bash

for file in ./**/*.md; do
  bunx --yes genaiscript run frontmatter "$file" --apply-edits
