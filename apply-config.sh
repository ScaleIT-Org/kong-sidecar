API_DIR=/config/api/
ADMIN_API_URL=localhost:8001

echo "Waiting for kong..."
    while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' http://${ADMIN_API_URL})" != "200" ]]; do 
        sleep 5; 
    done
echo "Kong endpoint available"

echo "Applying kong config files..."
for file in ${API_DIR}*.{yml,yaml,json}; do
    [ -e "$file" ] || continue

    kongfig apply --path $file --host $ADMIN_API_URL
    echo "${file} config applied."
done
echo "Done"