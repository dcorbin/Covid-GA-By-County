#!/bin/bash
set -e
set -x
date

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd ${DIR}
export DATA_DIR="${DIR}/production-data"

export PATH=${PATH}:/usr/local/bin
/usr/local/var/rbenv/shims/ruby fetch.rb
/usr/local/var/rbenv/shims/ruby post_fetch_processor.rb