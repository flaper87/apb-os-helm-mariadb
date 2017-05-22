FROM centos:7
MAINTAINER Ansible Playbook Bundle Community

LABEL "com.redhat.apb.version"="0.1.0"
LABEL "com.redhat.apb.spec"=\
"aWQ6IDU1YzUzYTVkLTY1YTYtNGMyNy04OGZjLWUwMjc0MTBiMTg4MgpuYW1lOiBoZWxsby13b3Js\
ZC1hcGIKaW1hZ2U6IGFuc2libGVwbGF5Ym9va2J1bmRsZS9oZWxsby13b3JsZC1hcGIKZGVzY3Jp\
cHRpb246ICJoZWxsby13b3JsZC1hcGIgZGVzY3JpcHRpb24iCmJpbmRhYmxlOiBmYWxzZQphc3lu\
Yzogb3B0aW9uYWwK"

ENV USER_NAME=apb \
    USER_UID=1001 \
    BASE_DIR=/opt/apb \
    ANSIBLE_LIBRARY=/opt/apb
ENV HOME=${BASE_DIR}

RUN mkdir -p /root/.kube /usr/share/ansible/openshift \
             /etc/ansible /opt/ansible \
             ${BASE_DIR} ${BASE_DIR}/etc \
             ${BASE_DIR}/.kube ${BASE_DIR}/.ansible/tmp && \
             useradd -u ${USER_UID} -r -g 0 -M -d ${BASE_DIR} -b ${BASE_DIR} -s /sbin/nologin -c "apb user" ${USER_NAME} && \
             chown -R ${USER_NAME}:0 /opt/{ansible,apb} && \
             chmod -R g+rw /opt/{ansible,apb} ${BASE_DIR} /etc/passwd

#COPY config /root/.kube/config
RUN curl https://copr.fedorainfracloud.org/coprs/jmontleon/asb/repo/epel-7/jmontleon-asb-epel-7.repo -o /etc/yum.repos.d/asb.repo
RUN yum -y install epel-release centos-release-openshift-origin \
    && yum -y update \
    && yum -y groupinstall 'Development Tools' \
    && yum -y install origin-clients python-openshift ansible ansible-kubernetes-modules pwgen python-pip python-pygit2 python-requests python-devel openssl-devel \
    && yum clean all

RUN echo "localhost ansible_connection=local" > /etc/ansible/hosts \
    && echo '[defaults]' > /etc/ansible/ansible.cfg \
    && echo 'roles_path = /etc/ansible/roles:/opt/ansible/roles' >> /etc/ansible/ansible.cfg

RUN pip install -U "git+https://github.com/flaper87/ansible"
RUN pip install "git+https://github.com/flaper87/pyhelm"

ADD playbooks /opt/apb/actions

ADD roles /opt/ansible/roles

COPY entrypoint.sh /usr/bin/
USER apb
RUN sed "s@${USER_NAME}:x:${USER_UID}:@${USER_NAME}:x:\${USER_ID}:@g" /etc/passwd > ${BASE_DIR}/etc/passwd.template
ENTRYPOINT ["entrypoint.sh"]