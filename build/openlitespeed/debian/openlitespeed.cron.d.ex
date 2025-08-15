#
# Regular cron jobs for the openlitespeed package
#
0 4	* * *	root	[ -x /usr/bin/openlitespeed_maintenance ] && /usr/bin/openlitespeed_maintenance
