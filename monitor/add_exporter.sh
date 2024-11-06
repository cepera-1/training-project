#!/bin/bash

set -x

if [ -z $1 ] || [ -z $2 ]
then
	echo "Введите имя и адрес экспортера"
fi
echo -e "\n  - job_name: $1
    scrape_interval: 5s
    scrape_timeout: 5s
    static_configs:
      - targets: ['$2']" >> /etc/prometheus/prometheus.yml 
