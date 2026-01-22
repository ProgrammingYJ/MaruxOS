#!/bin/sh
########################################################################
# Begin /lib/services/dhcpcd
#
# Description : DHCPCD Service Script
########################################################################

. /lib/lsb/init-functions
. /lib/services/init-functions

case "${2}" in
   up)
      log_info_msg "Starting dhcpcd on ${1}..."
      /usr/sbin/dhcpcd ${1}
      evaluate_retval
      ;;

   down)
      log_info_msg "Stopping dhcpcd on ${1}..."
      /usr/sbin/dhcpcd -k ${1} 2>/dev/null
      evaluate_retval
      ;;

   *)
      echo "Usage: ${0} interface {up|down}"
      exit 1
      ;;
esac

# End /lib/services/dhcpcd
