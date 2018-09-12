DOCKERFILE=$1

if [ -z "$DOCKERFILE" ]; then
    DOCKERFILE=./DockerSnort
fi

sudo docker build -t snort-container $DOCKERFILE
