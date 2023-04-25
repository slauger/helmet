FROM registry.access.redhat.com/ubi8/ubi@sha256:8b8cc63bcc10374ef349ec4f27a3aa1eb2dcd5a098d4f5f51fafac4df5db3fd7 AS builder

# renovate: datasource=github-tags depName=helm/helm
ARG HELM_VERSION=3.10.1

# renovate: datasource=github-tags depName=jkroepke/helm-secrets
ARG HELM_SECRETS_VERSION=4.1.1

# renovate: datasource=github-tags depName=databus23/helm-diff
ARG HELM_DIFF_VERSION=3.6.0

# renovate: datasource=github-tags depName=aslafy-z/helm-git
ARG HELM_GIT_VERSION=0.13.0

# renovate: datasource=github-tags depName=helmfile/helmfile
ARG HELMFILE_VERSION=0.147.0

# renovate: datasource=github-tags depName=mozilla/sops
ARG SOPS_VERSION=3.7.3

# renovate: datasource=github-tags depName=FiloSottile/age
ARG AGE_VERSION=1.0.0

# renovate: datasource=github-tags depName=kubernetes/kubernetes
ARG KUBECTL_VERSION=1.25.9

# renovate: datasource=docker depName=quay.io/openshift-release-dev/ocp-release versioning=loose
ARG OPENSHIFT_VERSION=4.11.10

RUN yum install -y unzip && \
    yum clean all && \
    rm -rf /var/cache/dnf/*

# helm-secrets
RUN mkdir -p /usr/local/helm-plugins && \
    curl -fsSL -o helm-secrets.tar.gz https://github.com/jkroepke/helm-secrets/releases/download/v${HELM_SECRETS_VERSION}/helm-secrets.tar.gz && \
    tar vxzf helm-secrets.tar.gz -C /usr/local/helm-plugins && \
    rm helm-secrets.tar.gz

# helm-diff
RUN curl -fsSL -o helm-diff-linux-amd64.tgz https://github.com/databus23/helm-diff/releases/download/v${HELM_DIFF_VERSION}/helm-diff-linux-amd64.tgz && \
    tar vxzf helm-diff-linux-amd64.tgz -C /usr/local/helm-plugins && \
    rm helm-diff-linux-amd64.tgz

# helm-git
RUN curl -fsSL -o helm-git.zip https://github.com/aslafy-z/helm-git/archive/refs/tags/v${HELM_GIT_VERSION}.zip && \
    unzip helm-git.zip -d /usr/local/helm-plugins && \
    rm helm-git.zip

# helm
RUN curl -fsSL -o helm-linux-amd64.tar.gz https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz && \
    tar vxzf helm-linux-amd64.tar.gz linux-amd64/helm && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    chmod +x /usr/local/bin/helm && \
    rm helm-linux-amd64.tar.gz && \
    rm -rf linux-amd64

# helmfile
RUN curl -fsSL -o helmfile_linux_amd64.tar.gz https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_${HELMFILE_VERSION}_linux_amd64.tar.gz && \
    tar vxzf helmfile_linux_amd64.tar.gz helmfile && \
    mv helmfile /usr/local/bin/helmfile && \
    rm helmfile_linux_amd64.tar.gz

# sops
RUN curl -fsSL -o /usr/local/bin/sops https://github.com/mozilla/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux && \
    chmod +x /usr/local/bin/sops

# age
RUN curl -fsSL -o age-linux-amd64.tar.gz https://github.com/FiloSottile/age/releases/download/v${AGE_VERSION}/age-v${AGE_VERSION}-linux-amd64.tar.gz && \
    tar vxzf age-linux-amd64.tar.gz && \
    mv age/age /usr/local/bin/age && \
    mv age/age-keygen /usr/local/bin/age-keygen && \
    rm age-linux-amd64.tar.gz && \
    rm -rf age

# kubectl
RUN curl -fsSL -o /usr/local/bin/kubectl https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x /usr/local/bin/kubectl

# oc
RUN curl -fsSL -o openshift-client-linux.tar.gz https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${OPENSHIFT_VERSION}/openshift-client-linux.tar.gz && \
    tar vxzf openshift-client-linux.tar.gz oc && \
    mv oc /usr/local/bin/oc && \
    chmod +x /usr/local/bin/oc

# argocd-helmfile
COPY argocd-helmfile.sh /usr/local/bin/argocd-helmfile.sh
RUN chmod +x /usr/local/bin/argocd-helmfile.sh

FROM registry.access.redhat.com/ubi8/ubi@sha256:8b8cc63bcc10374ef349ec4f27a3aa1eb2dcd5a098d4f5f51fafac4df5db3fd7 AS runtime

ENV HELM_PLUGINS=/usr/local/helm-plugins

COPY --from=builder /usr/local/bin/helm /usr/local/bin/helmfile /usr/local/bin/sops /usr/local/bin/age /usr/local/bin/age-keygen /usr/local/bin/kubectl /usr/local/bin/oc /usr/local/bin/argocd-helmfile.sh /usr/local/bin/
COPY --from=builder /usr/local/helm-plugins /usr/local/helm-plugins
