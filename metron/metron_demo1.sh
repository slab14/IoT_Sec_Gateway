#!/bin/bash

git clone https://git-wip-us.apache.org/repos/asf/metron.git
cd metron
git checkout apache-metron-0.5.0-rc2
mvn clean package -DskipTests
