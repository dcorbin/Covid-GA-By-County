#!/bin/bash
set -e
set -x
eval "$(rbenv init -)"
date >&2
date

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd ${DIR}/..
ruby fetch.rb
ruby -I ${DIR}/lib post_fetch_processor.rb
