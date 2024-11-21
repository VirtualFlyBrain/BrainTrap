ARG RUBY_VERSION=3.3
FROM ruby:$RUBY_VERSION

# Install dependencies
RUN apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get -yq dist-upgrade \
    && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && truncate -s 0 /var/log/*log

# Upgrade RubyGems and install Rails
RUN gem update --system \
    && gem install rails \
    && gem install pg

# Install postgres and fcgi
RUN apt-get update -qq \
    && DEBIAN_FRONTEND=noninteractive apt-get install -yq libfcgi-dev nano sudo postgresql \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && truncate -s 0 /var/log/*log \
    && gem install fcgi

# Create the database
COPY db/braintrap_development_live_10_01_2012.sql /tmp/braintrap_development_live_10_01_2012.sql
ENV DATABASE_URL="postgres://wwwdata:BrAi7nt4apDB@localhost/braintrap"
ENV PGDATA=/var/lib/postgresql-static/data
RUN mkdir -p $PGDATA \
    && service postgresql start \
    && sudo -u postgres createdb braintrap \
    && sudo -u postgres createuser -e wwwdata \
    && sudo -u postgres psql -c "ALTER USER wwwdata PASSWORD 'BrAi7nt4apDB';" \
    && sudo -u postgres psql -c "ALTER USER wwwdata CREATEDB;" \
    && rails new braintrap --database=postgresql \
    && cd braintrap \
    && rails db:create \
    && sudo -u postgres psql -d braintrap -a -f /tmp/braintrap_development_live_10_01_2012.sql \
    && service postgresql stop

# Copy the website
COPY ./app/ /braintrap/app/
COPY ./config/environment_new.rb /braintrap/config/environment.rb
COPY ./config/routes_new.rb /braintrap/config/routes.rb
COPY ./lib/ /braintrap/lib/
COPY ./public/ /braintrap/app/assets/
COPY ./public/images/ /braintrap/public/images/
COPY ./public/cite/ /braintrap/public/cite/
COPY ./config/application.rb /braintrap/config/application.rb

# Rename all .rhtml to .html.erb
RUN for f in /braintrap/app/views/*/*.rhtml; do mv -- "$f" "${f%.rhtml}.html.erb"; done

WORKDIR /braintrap

CMD ["bash", "-c", "service postgresql start && rails server -b 0.0.0.0"]
