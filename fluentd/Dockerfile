# fluentd/Dockerfile

FROM fluent/fluentd:v1.15.3-debian-1.0
USER root
RUN ["apt", "update"]
RUN gem uninstall -I elasticsearch && gem install elasticsearch -v 7.17.0
# RUN ["apt", "install", "-y", "libgmp-dev", "ruby-dev"]
RUN ["gem", "install", "fluent-plugin-elasticsearch", "--no-document", "--version", "4.3.3"]
# RUN ["gem", "install", "oj"]
USER fluent
