FROM containers.intersystems.com/intersystems/iris-community

ENV PIP_TARGET=${ISC_PACKAGE_INSTALLDIR}/mgr/python

RUN python3 -m pip install --upgrade pip && \
  pip install pandas sqlalchemy-iris
