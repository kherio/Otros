#!/bin/bash
set -u

# settings
# Login information of freenom.com
freenom_email="main@address"
freenom_passwd="pswd"
# Open DNS management page in your browser.
# URL vs settings:
#   https://my.freenom.com/clientarea.php?managedns={freenom_domain_name}&domainid={freenom_domain_id}
freenom_domain_name="domain.name"
freenom_domain_id="000000000"
BASE_URL="https://my.freenom.com"
CAREA_URL="$BASE_URL/clientarea.php"
LOGIN_URL="$BASE_URL/dologin.php"
LOGOUT_URL="$BASE_URL/logout.php"
MANAGED_URL="$CAREA_URL?managedns=$freenom_domain_name&domainid=$freenom_domain_id"
GET_IP_URL="https://api.ipify.org/"

# get current ip address
current_ip="$(curl -s "$GET_IP_URL")"

if [ -z "$current_ip" ]; then
    echo "Could not get current IP address." 1>&2
    exit 1
fi

cookie_file=$(mktemp)
cleanup() {
    echo "Cleanup"
    rm -f "$cookie_file"
}
trap cleanup INT EXIT TERM

echo "Login"
loginResult=$(curl --compressed -k -L -c "$cookie_file" \
                   -F "username=$freenom_email" -F "password=$freenom_passwd" \
                   -e "$CAREA_URL" \
                   "$LOGIN_URL" 2>&1)

if [ ! -s "$cookie_file" ]; then
    echo "Login failed: empty cookie." 1>&2
    exit 1
fi

if echo "$loginResult" | grep -q "/clientarea.php?incorrect=true"; then
    echo "Login failed." 1>&2
    exit 1
fi

echo "Update $current_ip to domain($freenom_domain_name)"
updateResult=$(curl --compressed -k -L -b "$cookie_file" \
                    -e "$MANAGED_URL" \
                    -F "dnsaction=modify" \
                    -F "records[0][line]=" \
                    -F "records[0][type]=A" \
                    -F "records[0][name]=" \
                    -F "records[0][ttl]=14440" \
                    -F "records[0][value]=$current_ip" \
                    "$MANAGED_URL" 2>&1)

if ! echo "$updateResult" | grep -q "name=\"records\[0\]\[value\]\" value=\"$current_ip\""; then
    echo "Update failed." 1>&2
    exit 1
fi

echo "Logout"
curl --compressed -k -b "$cookie_file" "$LOGOUT_URL" > /dev/null 2>&1

exit 0
