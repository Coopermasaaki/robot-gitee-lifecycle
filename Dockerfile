FROM openeuler/openeuler:23.03 as BUILDER
RUN dnf update -y && \
    dnf install -y golang && \
    go env -w GOPROXY=https://goproxy.cn,direct

MAINTAINER zengchen1024<chenzeng765@gmail.com>

# build binary
WORKDIR /go/src/github.com/opensourceways/robot-gitee-lifecycle
COPY . .
RUN GO111MODULE=on CGO_ENABLED=0 go build -a -o robot-gitee-lifecycle -buildmode=pie --ldflags "-s -linkmode 'external' -extldflags '-Wl,-z,now'" .

# copy binary config and utils
FROM openeuler/openeuler:22.03
RUN dnf -y update && \
    dnf in -y shadow && \
    dnf remove -y gdb-gdbserver && \
    groupadd -g 1000 lifecycle && \
    useradd -u 1000 -g lifecycle -s /sbin/nologin -m lifecycle && \
    echo > /etc/issue && echo > /etc/issue.net && echo > /etc/motd && \
    mkdir /home/lifecycle -p && \
    chmod 700 /home/lifecycle && \
    chown lifecycle:lifecycle /home/lifecycle && \
    echo 'set +o history' >> /root/.bashrc && \
    sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs && \
    rm -rf /tmp/*

USER lifecycle

WORKDIR /opt/app

COPY  --chown=lifecycle --from=BUILDER /go/src/github.com/opensourceways/robot-gitee-lifecycle/robot-gitee-lifecycle /opt/app/robot-gitee-lifecycle

RUN chmod 550 /opt/app/robot-gitee-lifecycle && \
    echo "umask 027" >> /home/lifecycle/.bashrc && \
    echo 'set +o history' >> /home/lifecycle/.bashrc

ENTRYPOINT ["/opt/app/robot-gitee-lifecycle"]
