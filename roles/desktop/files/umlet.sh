#!/bin/bash
exec java -Dsun.java2d.uiScale=2 -Dsun.java2d.xrender=f -jar /opt/umlet/umlet.jar "$@"
