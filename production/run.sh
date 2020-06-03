#!/bin/bash
set -e
set -x
eval "$(rbenv init -)"
date >&2
date

DIR="$(dirname "$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )")"
cd "${DIR}"
ruby fetch.rb
ruby -I ./lib post_fetch_processor.rb
cp "${DATA_DIR}"/table.json /var/www/covid/GA-By-County.json
mail -s "covid.dcorbin.com - data fetch complete" dave@dcorbin.com </dev/null
echo "Execution Complete" >&2
