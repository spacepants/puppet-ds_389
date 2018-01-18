#!/bin/sh

read -r -d '' REINIT << EOM
dn: cn=${PT_replica_name}Agreement,cn=replica,cn="${PT_suffix}",cn=mapping tree,cn=config
changetype: modify
replace: nsds5BeginReplicaRefresh
nsds5BeginReplicaRefresh: start
EOM

if [ $PT_starttls ]
then
  LM_OPTS='ZxH'
else
  LM_OPTS='xH'
fi

echo "$REINIT" | ldapmodify -$LM_OPTS $PT_protocol://$PT_server_host:$PT_server_port -x -D "${PT_root_dn}" -w $PT_root_dn_pass
