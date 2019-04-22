FROM centos:latest
ARG RUBY_SCL="rh-ruby25"
ENV ENTRYPOINT="/opt/rh/${RUBY_SCL}/enable"

RUN \
  echo "tsflags=nodocs" >> /etc/yum.conf && \
  yum -y install tokyocabinet-devel centos-release-scl gcc gcc-c++ patch libxml2-devel bzip2-devel make && \
  yum -y install ${RUBY_SCL} ${RUBY_SCL}-ruby{-devel,gems} ${RUBY_SCL}-rubygem-{rdoc,rake} && \
  yum clean all && \
  rm -rf /var/cache/yum/

ENV HOME=/home/rbot
WORKDIR $HOME
RUN groupadd -r rbot -f -g 1001 && \
    useradd -u 1001 -r -g rbot -d $HOME -s /sbin/nologin \
    -c "rbot Application User" rbot && \
    chown -R 1001:1001 $HOME

USER 1001
ENV GEM_HOME=${HOME}/.gems
ENV PATH=${HOME}/.gems/bin:${PATH}

RUN . ${ENTRYPOINT} && gem install -N mechanize tzinfo tokyocabinet && rm -rf .gems/cache/
RUN cd /tmp && \
  curl -L https://github.com/ruby-rbot/rbot/archive/master.tar.gz |tar xzvf - && \
  cd rbot-master && \
# PATCHES needed for RBOT
  sed -i '1s/^/require "rake" \n/' rbot.gemspec && \
  sed -i 's/README.rdoc/README.md/' rbot.gemspec && \
  sed -i 's/rbot.1/rbot.xml/' rbot.gemspec && \
  . ${ENTRYPOINT} && gem build rbot.gemspec && \
  gem install -N rbot-0.9.15.gem && \
  cd ${HOME} && rm -rf rbot-master

CMD . ${ENTRYPOINT} && rbot
