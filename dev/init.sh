#!/bin/bash
ln -sf /src/conjur-server/engines/conjur_audit/db/migrate/* /src/conjur-server/db/migrate
/sbin/my_init
