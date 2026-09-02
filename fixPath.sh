
if [[ $1 == C:* ]]; then
  echo $1 | sed -e 's/C:\\Users\\PrismaBiotech\\/\/mnt\/jsyfNAS\/jsyf0726\//' -e 's/\\/\//g'
fi
