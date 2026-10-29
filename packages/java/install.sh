#!/bin/sh
#
# SDKMan (https://sdkman.io/)
#
# Install SDK Man

# Check for SDKMan installed
if test ! $(which sdk)
then
  echo "  Installing SDKMan for you."
  
  /bin/bash -c "curl -s "https://get.sdkman.io" | bash"
fi

exit 0
