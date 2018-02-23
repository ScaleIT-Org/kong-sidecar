APIS_FILE=/config/api/apis.yml
CONSUMERS_FILE=/config/api/consumers.yml
ADMIN_API_URL=http://localhost:8001

echo "Waiting for kong..."
    while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' ${ADMIN_API_URL})" != "200" ]]; do 
        sleep 5; 
    done
echo "Kong endpoint available"

echo "Applying kong config files..."
for file in /Data/*.{yml,yaml,json}; do
    [ -e "$file" ] || continue

    kongfig apply --path $file --host $ADMIN_API_URL
    echo "${file} config applied."
done
echo "Done"