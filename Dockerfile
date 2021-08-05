# (c) Copyright 2021 Hewlett Packard Enterprise Development LP
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
#
# Note: If building behind a proxy use:
#
#    docker build --build-arg http_proxy=http://proxy.example.com \
#                 --build-arg https_proxy=http://proxy.example.com \
#                 --tag greenlake-ecr-auth-tools .

ARG ALPINE=alpine:3.13.5

FROM $ALPINE as kubectl
ARG KUBECTL_VERSION="v1.21.3"

RUN apk add --update --no-cache curl ca-certificates \
 && curl -LO https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl \
 && echo "$(curl -L https://dl.k8s.io/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256)  kubectl" > checksumfile \
 # Note: Don't use pipe (|) here -- so that building reliably
 #       detects any checksum error
 && sha256sum -c checksumfile \
 && chmod +x kubectl

FROM $ALPINE
ARG AWSCLI_VERSION=1.16.314
ARG USER=ecr

COPY --from=kubectl /kubectl /usr/local/bin/kubectl
RUN apk add --update --no-cache python3 cmd:pip3 py3-virtualenv \
      groff ca-certificates

RUN addgroup ${USER} \
    && adduser \
       --disabled-password \
       --gecos "" \
       --home /home/${USER} \
       --ingroup ${USER} \
       ${USER}

RUN ln -s /home/${USER}/aws/env/bin/aws /usr/local/bin/aws

USER ${USER}
WORKDIR /home/${USER}
RUN mkdir aws \
    && virtualenv aws/env \
    && ./aws/env/bin/pip install awscli==${AWSCLI_VERSION} \
    # Sanity check
    && aws --version \
    && kubectl version --client=true
