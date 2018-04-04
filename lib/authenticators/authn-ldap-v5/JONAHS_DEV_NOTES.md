

from Dustin:

yeah, jenkins will run your test suite - after tests pass it should push the
resulting image to dockerhub. VERSION may still be useful here, to use when
creating the version tag for the docker image - more explicit than trying to go
off tags

template Jenkins file:
https://github.com/conjurinc/ami-promoter/blob/master/Jenkinsfile

you’ll just want to add a middle stage where we run tests



# OLD NOTES
write readme
  main one and for test/dev
make jenkins work
test on jenkins
check if my rerun thing will be an issue in prod

stuff jason said about old readme and branch whaever
  make this master, put the old one an a tag


    Kevin Gilpin [2 minutes ago]
    Well, start by making VERSION_APPLIANCE = “5.0”, update the major version in the VERSION file, and update the changelog


    Kevin Gilpin [2 minutes ago]
    Then show Dustin what you’re up to :slightly_smiling_face:


## Exposing extension via nginx reverse proxy

You define your extensions endpoint in the extension project (authn-ldap in
this case), and then you expose it the appliance's nginx using volumes (or
something like that)

From [Kevin's document](https://cyberark365-my.sharepoint.com/:w:/r/personal/kgilpin_cyberark_com/_layouts/15/WopiFrame.aspx?sourcedoc=%7Bb42fd1f3-ac9c-4401-816e-1960d45f33ee%7D&action=view&wdAccPdf=0):

The config file `40_authn-ldap.conf` would be something like:

    location /api/authn-ldap/ {
      proxy_pass http://authn-ldap/;
    }
