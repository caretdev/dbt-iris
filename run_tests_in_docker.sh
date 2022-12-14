#!/bin/bash

iris_start () {
  iris start iris

  iris session iris -U %SYS '##class(Security.Users).UnExpireUserPasswords("*")'
}

iris_stop () {
  iris stop iris quietly
}

iris_start

pytest

exit=$?

if [ $exit -ne 0 ]; then
  iris_stop
  exit $exit
fi

cd $HOME

git clone --depth 1 https://github.com/dbt-labs/jaffle_shop.git

cd jaffle_shop

git pull

mkdir -p $HOME/.dbt

cat > $HOME/.dbt/profiles.yml <<EOF

jaffle_shop:

  target: dev
  outputs:
    dev:
      type: iris
      host: localhost
      port: 1972
      user: _SYSTEM
      pass: SYS
      namespace: USER
      schema: dbt

EOF

dbt seed
dbt run
dbt test
dbt docs generate

exit=$?

iris_stop
exit $exit
