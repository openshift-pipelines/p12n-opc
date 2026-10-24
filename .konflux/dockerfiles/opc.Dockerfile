ARG GO_BUILDER=registry.access.redhat.com/ubi9/go-toolset:latest@sha256:edb9452603fa48e9882063f001ecd7d322add20f1564a4f05f38f6683be5ea94
ARG RUNTIME=registry.access.redhat.com/ubi9/ubi-minimal:9.8-1792742033@sha256:2d4c4551af6831dcd26bbf86108c4385de5183ec8fe6b5868f6f9640fe47f4ed


FROM $GO_BUILDER AS builder

WORKDIR /go/src/github.com/openshift-pipelines/opc
COPY upstream .
COPY .konflux/patches patches/
RUN set -e; for f in patches/*.patch; do echo ${f}; [[ -f ${f} ]] || continue; git apply ${f}; done
ENV GOEXPERIMENT="strictfipsruntime"
RUN go build -buildvcs=false -mod=vendor -tags disable_gcp,strictfipsruntime  -o /tmp/opc main.go

FROM $RUNTIME
ARG VERSION=1.21
COPY --from=builder /tmp/opc /usr/bin

RUN groupadd -r -g 65532 nonroot && useradd --no-log-init -r -u 65532 -g nonroot nonroot
USER 65532

LABEL \
    com.redhat.component="openshift-pipelines-opc-rhel9-container" \
    cpe="cpe:/a:redhat:openshift_pipelines:1.21::el9" \
    description="Red Hat OpenShift Pipelines opc opc" \
    io.k8s.description="Red Hat OpenShift Pipelines opc opc" \
    io.k8s.display-name="Red Hat OpenShift Pipelines opc opc" \
    io.openshift.tags="tekton,openshift,opc,opc" \
    maintainer="pipelines-extcomm@redhat.com" \
    name="openshift-pipelines/pipelines-opc-rhel9" \
    summary="Red Hat OpenShift Pipelines opc opc" \
    version="v1.21.4"
