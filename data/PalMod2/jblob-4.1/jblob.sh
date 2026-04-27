#!/bin/bash

# For debugging uncomment next line
#set -xv

# Installation directory, set to local installation directory
#JBLOB_HOME=/opt/jblob-4.1
JBLOB_HOME="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Java directory, uncomment and edit if global JAVA_HOME is not set
#JAVA_HOME=/usr/lib/jvm/java

# Try to locate java home from config if necessary
if [ ! -x "$JAVA_HOME/bin/java" ] ; then
  echo "Cannot find java binary. Please check if \$JAVA_HOME is set correctly!"
  exit 1
fi

# Start java application
$JAVA_HOME/bin/java -Xmx100m -cp $JBLOB_HOME/lib/jblob.jar de.dkrz.cera.application.JblobClient "$@"

