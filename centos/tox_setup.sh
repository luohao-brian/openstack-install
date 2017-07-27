#!/bin/bash

yum install -y libffi-devel postgresql postgresql-devel
pip list |grep tox || {
    pip install tox
}
