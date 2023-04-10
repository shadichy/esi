#!/bin/bash

echo "Bundling components"

echo '#!/bin/bash' >script_dist/install.sh
sed -r ':a;N;$!ba;s/(^(\s*(#.*\n)?|\n+))//gm' core/*.sh |
  sed -r "s/=(''|\"\")/=/gm" |
  sed -r 's/\)\s+\{/\)\{/gm' |
  sed -r 's/\s*(;|\()\s*/\1/gm' |
  sed -r 's/\s*(\))/\1/gm' |
  sed -r ':a;N;$!ba;s/([^\\])\\\n/\1 /gm' |
  sed -r ':a;N;$!ba;s/^([^\(]+)\)\s*\n*(.+)$/\1)\2/gm' |
  sed -r ':a;N;$!ba;s/\s*\n*((;|\||&){1,2})\s*\n*/\1/gm' |
  sed -r 's/ {2,}/ /gm' >>script_dist/install.sh
