#!/bin/bash
set -e
set -x
date

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd ${DIR}

export PATH=${PATH}:/usr/local/bin
/usr/local/var/rbenv/shims/ruby fetch.rb
