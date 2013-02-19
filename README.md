deployment
==========

Deployment Tools


* deploy.sh
  Given a build number will unzip an archive with the given build number, copy all relavent configs from a 'config' directory in the same directory and run toggle-omeroweb.sh against the reference dirertory.
* toggle-omeroweb.sh
  Given two directories will start omeroweb on one of two open ports and attempt to gracefully shutdown the previous one.
