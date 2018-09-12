#!/bin/bash

sudo systemctl disable apparmor.service --now
sudo service apparmor teardown
