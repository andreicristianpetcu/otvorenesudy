# Open Courts (Otvorené Súdy in Slovak)

Public data project aimed at creating much more user friendly interface to interesting public data provided by [Departement of Justice](http://www.justice.gov.sk) and [The Judical Council](http://www.sudnarada.sk) of the Slovak Republic.

## Setup

### Requirements

* Ruby 1.9.3
* Rails 3
* PostgreSQL with trigram extension
* Redis & Resque
* Elasticsearch

### Project and Database

```
sudo apt-get install git curl libcurl3 libcurl3-gnutls libcurl4-openssl-dev libpq-dev postgresql-client postgresql -y
sudo -u postgres createuser -s $USER
sudo -u postgres createdatabase -s $USER
sudo -u postgres createdb $USER

sudo -u postgres psql -c "CREATE USER opencourts WITH PASSWORD 'opencourts' SUPERUSER CREATEDB CREATEROLE;"

# do this http://stackoverflow.com/questions/17443379/psql-fatal-peer-authentication-failed-for-user-dev/21889759#21889759

curl https://raw.github.com/fesplugas/rbenv-installer/master/bin/rbenv-installer | bash
# add rbenv to your path
echo 'export RBENV_ROOT="${HOME}/.rbenv"
if [ -d "${RBENV_ROOT}" ]; then
  export PATH="${RBENV_ROOT}/bin:${PATH}"
  eval "$(rbenv init -)"
fi' | tee -a ~/.bash_profile

#logout, login
rbenv bootstrap-ubuntu-12-04
rbenv install 2.1.0

git clone git://github.com/otvorenesudy/otvorenesudy.git
cd otvorenesudy
rbenv local 2.1.0
gem install bundler
git submodule init   # initialize submodule, e.g. otvorenesudy-data
git submodule update # or git submodule foreach git pull origin master
bundle install
cp config/database.{yml.example,yml}
```

Open `config/database.yml` and edit database configuration.
Set `$RAILS_ENV` variable to your environment (development, test) and create the database.

```
# check this out https://gist.github.com/ffmike/877447
RAILS_ENV=development
rake db:create
```

### PostgreSQL Trigram extension

```
sudo apt-get install postgresql-contrib -y
sudo service postgresql restart
cd /usr/share/postgresql/9.1/extension/
sudo su postgres
RAILS_ENV=development
psql -U postgres -d opencourts_$RAILS_ENV -f pg_trgm--1.0.sql
exit
```

Note that you need to set up the Trigram extension for all Rails environments you plan to use separatly.

### Elasticsearch
sudo apt-get install openjdk-7-jre -y
cd ~/
wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.1.1.zip
unzip elasticsearch-1.1.1.zip -d elasticsearch
cd elasticsearch/elasticsearch-1.1.1
bin/elasticsearch
Follow the [offical installation guide](https://github.com/elasticsearch/elasticsearch).

### PDF processing

```
sudo apt-get install graphicsmagick -y
sudo apt-get install tesseract-ocr -y
```

### Tests

Run tests by `rspec` to check if the setup is complete.
Be sure to add PostgreSQL Trigram extension to the test database `RAILS_ENV=test` and then setup database by running `rake db:setup RAILS_ENV=test`.
Tests do not assume any data in the database, since `FactoryGirl` creates sample model instances.

To quicky setup a small database with real production data for development purposes run `rake fixtures:db:setup` command.

## Data

Setup database:

```
cd ~/otvorenesudy
cp config/configuration.{yml.example,yml}
#set secret tocen to something line secret_token: 3a8311d259e630f0403af07ee078ad7f
rake db:setup
```

The `db:setup` task loads schema and seed data. Note that the seed data are essential for the next steps.

Crawl the necessary data, courts and judges from justice.gov.sk:

```
# you are here
rake crawl:courts
rake crawl:judges
```

Add court acronyms:

```
rake process:court_acronyms
```

Process known paragraph descriptions:

```
rake process:paragraphs
```

### Hearings and decrees from justice.gov.sk

Start Resque workers:

```
rake resque:workers QUEUE=* COUNT=4
```

Crawl and process hearings and decrees using Resque workers in any order:

```
rake work:hearings:civil
rake work:hearings:criminal
rake work:hearings:special
rake work:decrees
```

### Judge property declarations from sudnarada.gov.sk

Crawl judge property declarations:

```
rake crawl:judge_property_declarations
```

Note that currect support is only for property declarations of 2011 and 2012.

### Partially preprocessed statistical summaries from justice.gov.sk

Court statistical summaries:

```
rake process:court_statistical_summaries:2011
rake process:court_statistical_summaries:2012
```

Judge statistical summaries:

```
rake process:judge_statistical_summaries:2011
rake process:judge_statistical_summaries:2012
```

### Partially preprocessed data from various sources

Court expenses from justice.gov.sk:

```
rake process:court_expenses:2010
rake process:court_expenses:2011
rake process:court_expenses:2012
```

Process judge designations from nrsr.sk and prezident.sk:

```
rake process:judge_designations:nrsr_sk
rake process:judge_designations:prezident_sk
```

## Contributing

1. Fork it
2. Create your feature branch `git checkout -b new-feature`
3. Commit your changes `git commit -am 'Added some feature'`
4. Push to the branch `git push origin new-feature`
5. Create new Pull Request

## License

[Educational Community License 1.0](http://opensource.org/licenses/ecl1.php)
