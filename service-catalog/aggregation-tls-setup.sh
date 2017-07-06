#!/bin/bash

# Copyright 2017 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

CUR=$(pwd)
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo "Entering $DIR"
cd $DIR

export HELM_NAME=catalog
export SVCCAT_NAMESPACE=catalog
export SVCCAT_SERVICE_NAME=${HELM_NAME}-${SVCCAT_NAMESPACE}-apiserver

export CA_NAME=ca

export ALT_NAMES="\"${SVCCAT_SERVICE_NAME}.${SVCCAT_NAMESPACE}\",\"${SVCCAT_SERVICE_NAME}.${SVCCAT_NAMESPACE}.svc"\"

export SVCCAT_CA_SETUP=svc-cat-ca.json
cat > ${SVCCAT_CA_SETUP} << EOF
{
    "hosts": [ ${ALT_NAMES} ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "US",
            "L": "san jose",
            "O": "kube",
            "OU": "WWW",
            "ST": "California"
        }
    ]
}
EOF


cfssl genkey --initca ${SVCCAT_CA_SETUP} | cfssljson -bare ${CA_NAME}
# now the files 'ca.csr, ca-key.pem, and ca.pem' exist

export SVCCAT_CA_CERT=${CA_NAME}.pem
export SVCCAT_CA_KEY=${CA_NAME}-key.pem

export PURPOSE=server
echo '{"signing":{"default":{"expiry":"43800h","usages":["signing","key encipherment","'${PURPOSE}'"]}}}' > "${PURPOSE}-ca-config.json"

echo '{"CN":"'${SVCCAT_SERVICE_NAME}'","hosts":['${ALT_NAMES}'],"key":{"algo":"rsa","size":2048}}' \
 | cfssl gencert -ca=${SVCCAT_CA_CERT} -ca-key=${SVCCAT_CA_KEY} -config=server-ca-config.json - \
 | cfssljson -bare apiserver

export SC_SERVING_CA=${SVCCAT_CA_CERT}
echo "Set SC_SERVING_CA=${SC_SERVING_CA}"

export SC_SERVING_CERT=apiserver.pem
echo "Set SC_SERVING_CERT=${SC_SERVING_CERT}"

export SC_SERVING_KEY=apiserver-key.pem
echo "Set SC_SERVING_KEY=${SC_SERVING_KEY}"

echo "Done"