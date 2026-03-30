#!/bin/bash
# Copy connectors from plugins to lib
cp /opt/flink/plugins/connectors/*.jar /opt/flink/lib/
# Start SQL gateway
/opt/flink/bin/sql-gateway.sh start-foreground