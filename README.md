<p align="center">
  <img src="https://raw.githubusercontent.com/dbt-labs/dbt/ec7dee39f793aa4f7dd3dae37282cc87664813e4/etc/dbt-logo-full.svg" alt="dbt logo" width="500"/>
</p>

**[dbt](https://www.getdbt.com/)** enables data analysts and engineers to transform their data using the same practices that software engineers use to build applications.

dbt is the T in ELT. Organize, cleanse, denormalize, filter, rename, and pre-aggregate the raw data in your warehouse so that it's ready for analysis.

## InterSystems IRIS

[InterSystems IRIS](https://www.intersystems.com/data-platform/) is a data platform that provides advanced technologies for building and deploying data-intensive applications. It is a high-performance, multidimensional database that is optimized for complex data and real-time analytics. It is designed to support a wide range of data management, analysis, and integration tasks, and provides features such as a high-performance database engine, a powerful analytics engine, and support for building and deploying microservices. InterSystems IRIS is used by organizations in a variety of industries, including healthcare, finance, and government, to support their data-intensive applications and business processes.

### Start InterSystems IRIS Locally with Docker Compose

docker-compose.yml

```yml
version: '3'
services:
  iris:
    image: intersystemsdc/iris-community
    command:
      - -a
      # by default it starts with a requirement to change passwords for system users
      - iris session iris -U %SYS '##class(Security.Users).UnExpireUserPasswords("*")'
    ports:
      - 1972:1972
      - 52773:52773
```

Ports:

- 1972 - SuperPort - Binary protocol
- 52773 - Internal WebServer, internal System Management Portal is available by [http://localhost:52773/csp/sys/UtilHome.csp](http://localhost:52773/csp/sys/UtilHome.csp)

```shell
docker-compose up -d
```

_Default login and password `_SYSTEM` and `SYS`_

### Configure dbt

.dbt/profiles.yml

```yml
...
    iris:
      type: iris
      host: localhost
      port: 1972
      user: _SYSTEM
      pass: SYS
      namespace: USER
      schema: dbt
```

Required parameters:

- type = iris
- host | hostname | server
- port
- namespace | database
- user | username
- pass | password
- schema

## Useful Links

- [InterSystems Documentation](https://docs.intersystems.com/)
- [InterSystems Developer Community](http://community.intersystems.com/)
