FROM click:latest

COPY bridge.click bridge.click
COPY run.sh run.sh

# Run bridge application
CMD ["eth0", "eth1"]
ENTRYPOINT ["/run.sh"]

