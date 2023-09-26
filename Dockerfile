FROM containers.intersystems.com/intersystems/iris-community:2023.2

ENV PIP_TARGET=${ISC_PACKAGE_INSTALLDIR}/mgr/python

RUN python3 -m pip install --upgrade pip && \
  pip install pandas sqlalchemy-iris
