install:
	sudo curl -L https://github.com/liquidata-inc/dolt/releases/latest/download/install.sh | sudo bash
create:
	dolt config --global --add user.name "github action"
	dolt config --global --add user.email "actions@github.com"
	dolt init
	dolt sql -q 'CREATE TABLE county_records ( `date` TEXT, `county` TEXT, `state` TEXT, `fips` TEXT, `cases` int, `deaths` int, PRIMARY KEY (`date`,county,state) );'
download:
	curl 'https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv' > us-counties.csv

insert:
	dolt table import -u county_records -r us-counties.csv

normalize-fields:
	# dolt cant alter modify. applying workaround with additional column
	dolt sql -q 'alter table county_records add column d_date date;'
	dolt sql -q 'update county_records set d_date = cast(`date` as date), county = lower(county), state = lower(state) '

sum-by-county:
	dolt sql -q "select state,county, SUM(cases) as total from county_records group by state, county order by total asc"  -r csv > total.csv

clean:
	rm -rf ./.dolt ./*.csv

total: clean install create download insert normalize-fields sum-by-county
