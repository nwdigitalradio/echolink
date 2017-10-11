#!/bin/bash

# For conditioning network services
systemctl enable systemd-networkd.service
systemctl enable systemd-networkd-wait-online.service
