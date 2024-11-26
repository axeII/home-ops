#!/bin/bash

# on macos don't forget to updates bash to 5.x

DB_HOST="localhost"
DB_PORT="5432"
DB_USER=postgres

variables=("ROOT_PASSWORD" "DATABASE_NAME" "USERNAME" "PASSWORD")

declare -A map_of_answers

for var in ${variables[@]}; do
    echo -n "Enter a value for $var: "
    read input

    map_of_answers[$var]=$input
done

export PGPASSWORD=${map_of_answers["ROOT_PASSWORD"]}

# echo "psql -h $DB_HOST -p $DB_PORT -U $DB_USER -c CREATE USER ${map_of_answers["USERNAME"]} WITH PASSWORD '${map_of_answers["PASSWORD"]}' and db ${map_of_answers["DATABASE_NAME"]}"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -c "CREATE USER ${map_of_answers["USERNAME"]} WITH PASSWORD '${map_of_answers["PASSWORD"]}';"
psql -h $DB_HOST -p $DB_PORT -U $DB_USER -c "CREATE DATABASE ${map_of_answers["DATABASE_NAME"]} WITH OWNER ${map_of_answers["USERNAME"]};"

unset PGPASSWORD
