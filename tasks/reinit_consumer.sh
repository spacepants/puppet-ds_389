#!/bin/sh

read -r -d '' REINIT << EOM
dn: cn=${PT_replica_name}Agreement,cn=replica,cn="${PT_suffix}",cn=mapping tree,cn=config
changetype: modify
replace: nsds5BeginReplicaRefresh
nsds5BeginReplicaRefresh: start
EOM

echo "$REINIT" | ldapmodify -h $PT_server_host -p $PT_server_port -x -D "${PT_root_dn}" -w $PT_root_dn_pass
