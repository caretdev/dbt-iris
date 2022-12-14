FROM intersystemsdc/iris-community

USER root

RUN apt-get update && apt-get -y install git

USER ${ISC_PACKAGE_MGRUSER}

COPY --chown=${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_MGRGROUP} . /home/irisowner/dbt-iris

WORKDIR /home/irisowner/dbt-iris

ENV PATH="$PATH:/home/irisowner/.local/bin/"
ENV PYTHONPATH="/home/irisowner/dbt-iris"

RUN python3 -m pip install --upgrade pip \
  && pip install -r requirements-dev.txt -r requirements.txt

ENTRYPOINT [ "bash" ]
