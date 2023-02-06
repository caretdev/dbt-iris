FROM containers.intersystems.com/intersystems/iris-community:2022.3.0.606.0

ENV PIP_TARGET=${ISC_PACKAGE_INSTALLDIR}/mgr/python

RUN python3 -m pip install --upgrade pip && \
  pip install sqlalchemy~=1.4.46 pandas sqlalchemy-iris
