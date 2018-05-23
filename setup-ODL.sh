sudo apt-get update && \
    sudo apt-get install -yqq default-jdk default-jre maven

cd ~

git clone https://git.opendaylight.org/gerrit/integration/distribution

curl https://raw.githubusercontent.com/opendaylight/odlparent/master/settings.xml --create-dirs -o ~/.m2/settings.xml

#Optional
sudo apt-get install -yqq mininet
