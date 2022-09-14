FROM ubuntu:22.04 as builder

RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    cmake \
    bison \
    axel \
    libncurses5-dev \
    pkg-config

RUN axel -n 10 https://sourceforge.net/projects/boost/files/boost/1.59.0/boost_1_59_0.tar.gz \
    && tar -zxvf boost_1_59_0.tar.gz -C /usr/local/ \
    && rm boost_1_59_0.tar.gz

RUN axel https://www.openssl.org/source/openssl-1.1.1q.tar.gz \
    && tar -xf openssl-1.1.1q.tar.gz \
    && cd openssl-1.1.1q \
    && ./config --prefix=/usr/local/openssl --openssldir=/usr/local/openssl \
    && make \
    && make install \
    && cd .. \
    && rm -rf openssl-1.1.1q

RUN groupadd mysql \
    && useradd -r -g mysql mysql

RUN mkdir /usr/local/mysql \
    && chown -R mysql.mysql /usr/local/mysql

RUN mkdir /var/lib/mysql \
    && chown -R mysql.mysql /var/lib/mysql

RUN git clone --single-branch --branch mysql-5.7.39 --depth 1 https://github.com/mysql/mysql-server.git

RUN cd mysql-server \
    && cmake . -DCMAKE_INSTALL_PREFIX=/usr/local/mysql -DMYSQL_DATADIR=/var/lib/mysql -DWITH_BOOST=/usr/local/boost_1_59_0 -DSYSCONFDIR=/etc -DEXTRA_CHARSETS=all -DWITH_SSL=/usr/local/openssl \
    && make  \
    && make install \
    && rm -rf /usr/local/mysql/mysql-test \
    /usr/local/mysql/README-test \
    /usr/local/mysql/bin/mysqltest \
    /usr/local/mysql/bin/mysqltest_embedded \
    /usr/local/mysql/bin/mysqlxtest \
    /usr/local/mysql/bin/mysql_client_test \
    /usr/local/mysql/bin/mysql_client_test_embedded

FROM ubuntu:22.04
COPY --from=builder /usr/local/mysql /usr/local/mysql
COPY --from=builder /usr/lib/ssl/openssl.cnf /usr/lib/ssl/openssl.cnf
COPY --from=builder /usr/bin/openssl /usr/bin/openssl
COPY --from=builder /usr/local/openssl /usr/local/openssl
COPY --from=builder /etc/ssl/openssl.cnf /etc/ssl/openssl.cnf

ENV PATH="${PATH}:/usr/local/mysql/bin"

RUN groupadd mysql \
    && useradd -r -g mysql mysql

RUN mkdir -p /usr/local/mysql \
    && chown -R mysql.mysql /usr/local/mysql

RUN mkdir -p /var/lib/mysql \
    && chown -R mysql.mysql /var/lib/mysql

VOLUME /var/lib/mysql

COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]

USER mysql

EXPOSE 3306 33060
CMD ["mysqld"]
