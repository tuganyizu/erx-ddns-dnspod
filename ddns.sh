#!/bin/vbash
# An Edgerouter-X DDNS script for dnspod
# config
login_id='12345' # your id
login_token='1234567890abcdef1234567890abcdef' # your token
domain='www.youdomain.com'
agent="erx-ddns-dnspod/0.1(tuganyizu@gmail.com)"
# Log file record some,in case we have to debug our code
log_file="/config/scripts/ddns_dnspod/ddns_update.log"
# config end

echo "Start at $(date)"

post_data="login_token=${login_id},${login_token}&format=json&domain=${domain#*.}&sub_domain=${domain%%.*}"
# get record list
return_json_01=`curl -k -s -A ${agent} -X POST "https://dnsapi.cn/Record.List" -d "${post_data}"`
status_code_01=$(echo ${return_json_01}|jq -r ".status.code")
if [ "${status_code_01}" == '1' ]
then
    # domain_id=`jq -r ".domain.id" "step_01.json"`
    record_id=`echo ${return_json_01}|jq -r ".records[0].id"`
    record_line_id=`echo ${return_json_01}|jq -r ".records[0].line_id"`
    record_ip=`echo ${return_json_01}|jq -r ".records[0].ip"`
    current_ip=`/opt/vyatta/bin/vyatta-op-cmd-wrapper show interfaces|grep pppoe1|sed "s/.* \([0-9]*\.[0-9]*\.[0-9]*\.[0-9]*\).*/\1/"`
    # compare local current ip address with remote dns ip value.
    if [ "${current_ip}" != "${record_ip}" ]
    then
        echo "WAN IP is ${current_ip}"
        echo "DNS IP is ${record_ip}"
        # update remote dns ip value
        return_json_02=`curl -k -s -A ${agent} -X POST "https://dnsapi.cn/Record.Ddns" -d "${post_data}&record_line_id=${record_line_id}&record_id=${record_id}&value=${current_ip}"`
        status_code_02=$(echo ${return_json_02}|jq -r ".status.code")
        if [ "${status_code_02}" == '1' ]
        then
            echo "$(date) ${domain} ip address has been update with value ${current_ip}" >> ${log_file}
        else 
            echo "$(date) ${domain} ip update failed." >> ${log_file}
        fi
        echo "$(date) ${domain} no need to be updated." >> ${log_file}
    fi
else
    echo "Failed to get the record for ${domain} ${return_json_01}" >> ${log_file}
fi
echo "End at $(date)" >> ${log_file}
exit 0