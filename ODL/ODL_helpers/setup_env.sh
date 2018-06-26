sudo apt-get install -yqq default-jre default-jdk maven

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/
export PATH=$PATH:$JAVA_HOME/bin/

mkdir -p ~/.m2
cp /usr/share/maven/conf/settings.xml ~/.m2/settings.xml
cp -n ~/.m2/settings.xml{,.orig}
wget -q -O - https://raw.githubusercontent.com/opendaylight/odlparent/stable/boron/settings.xml > ~/.m2/settings.xml


export M2_HOME=/usr/share/maven/
export M2=$M2_HOME
export MAVEN_OPTS='-Xmx1048m -XX:MaxPermSize=512m -Xms256m'

export PATH=$M2:$PATH
