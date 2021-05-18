#!/bin/bash
domain='XXX'
#subDomain='server'
sId='XXX'
sKey='XXX'
signatureMethod='HmacSHA1'
timestamp=$(date +%s)
nonce=$(head -200 /dev/urandom | cksum | cut -f2 -d" ")
region=bj
url="https://cns.api.qcloud.com/v2/index.php"
#构建传入参数
bash_url () {
	action="${1}"
	src="GETcns.api.qcloud.com/v2/index.php?Action=${action}&Nonce=${nonce}&Region=${region}&SecretId=${sId}&SignatureMethod=${signatureMethod}&Timestamp=${timestamp}&domain=${domain}&${2}"
	#echo 'src: ' $src
	signature=$(echo -n "${src}"|openssl dgst -sha1 -hmac $sKey -binary |base64)
	#echo 'signature: ' $signature
	params="Action=${action}&domain=${domain}&Nonce=${nonce}&Region=${region}&SecretId=${sId}&Signature=${signature}&SignatureMethod=${signatureMethod}&Timestamp=${timestamp}&${2}"
}
#获取相关信息
get_RecordList_info () {
	if [ $# -ne 1 ];then
		echo "USE: get_RecordList_info subDomain "
                exit 1
	fi
	bash_url RecordList "subDomain=${1}"
        curl -s -G -d "${params}" --data-urlencode "Signature=${signature}" "${url}"
	#|jq -r ".data.records[].${1}"
}
#修改IP
RecordModify() {
	if [ $# -ne 4 ];then
                echo -e "USE: RecordModify value recordId subDomain recordType "
                exit 1
        fi
	bash_url RecordModify "recordId=${2}&recordLine=默认&recordType=${4}&subDomain=${3}&value=${1}"
	curl -s -G -d "${params}" --data-urlencode "Signature=${signature}" "${url}"
}
ipv6() {
	local subDomain=server
	local ipv6_recordId=$(get_RecordList_info ${subDomain} |jq -r .data.records[1].id)
	local ipv6_addr=$(ip addr show|grep inet6|grep 'scope global mngtmpaddr dynamic'|cut -d '/' -f 1|awk '{print $2}')
	RecordModify "${ipv6_addr}" "${ipv6_recordId}" "${subDomain}" AAAA
}
ipv4() {
        local subDomain=server
	local ipv4_recordId=$(get_RecordList_info ${subDomain} |jq -r .data.records[0].id)
        local ipv4_addr=${2}
        RecordModify "${ipv4_addr}" "${ipv4_recordId}" "${subDomain}" A
}
${1} ${2}
