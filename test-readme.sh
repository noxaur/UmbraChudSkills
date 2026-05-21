#!/bin/bash
# Test: README should not contain the typo 'recieve'
if grep -q "recieve" README.md; then
  echo "FAIL: Found typo 'recieve' in README.md"
  exit 1
else
  echo "PASS: No typo 'recieve' found"
  exit 0
fi
