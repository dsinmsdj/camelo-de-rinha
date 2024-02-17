FROM perl:5.38.0

WORKDIR /usr/src/app
EXPOSE 8081 8082

RUN cpanm Mojolicious -n
RUN cpanm Mojo::Pg -n

COPY . /usr/src/app
ARG PERL_HTTP_PORT
CMD ["hypnotoad", "-f", "camelo-de-rinha/main.pl"]
