## stable release generally has pom.xml files that reference non-existent dependencies. To fix this for Boron release change all pom.xml files that have a '*.*.5-SNAPSHOT' to '*.*.4-Boron-SR4'

## This is required to be able to build the controller project in any release that is prior to oxygen

find . -name 'pom.xml' -not -path '*/\.*' -type f -print0 | xargs -0 sed -i '' 's/\.5\-SNAPSHOT/.4-Boron-SR4/g'
