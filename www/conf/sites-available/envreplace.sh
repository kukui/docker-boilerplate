#!/bin/bash

# https://stackoverflow.com/questions/59895/can-a-bash-script-tell-which-directory-it-is-stored-in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
for file in $DIR/*.conf.var; do
    # replace occurences of the domain so that the appropriate certificate is linked
    (envsubst '$DOMAIN') < $file > $DIR/`basename $file .var`
done
