if [ -f /config/kong-apis.json ]; then
    echo "APIs config file detected, applying..."
    
    echo "Waiting for kong..."
    while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' localhost:8001)" != "200" ]]; do 
        sleep 5; 
    done
    echo "Kong endpoint available"

    for row in $(jq -c '.[]' /config/kong-apis.json); do
        # skip empty rows
        if [[ -z "${row// }" ]]; then
            continue
        fi
        
        name=$(echo $row | jq -r '.name')
        # check if API with name already exists otherwise update it
        res=$(curl -s -o /dev/null -w '%{http_code}\n' localhost:8001/apis/${name})
        if [ $res == 404 ]; then
            echo "Adding API ${name}:"
            curl -s -d ${row} -H "Content-Type: application/json" -X POST http://localhost:8001/apis | jq .
        else
            echo "Updating API ${name}:"
            curl -s -d ${row} -H "Content-Type: application/json" -X PATCH http://localhost:8001/apis/${name} | jq .
        fi

    done

    echo "API config applied"
else
    echo "No kong-apis file found, skipping configuration."
fi