#!/bin/bash
DB=${1:-audit}
P="psql -h /tmp/pg -p 54329 -U postgres -d $DB -qAt"
TABLES="companies studios profiles profile_contacts profile_notes studio_members bootstrap_owners class_types template_slots classes positions notifications check_ins attendance swap_requests absences challenges challenge_coaches pt_sessions coach_reviews extra_earnings"
printf "%-6s" role; for t in $TABLES; do printf " %s" $t; done; echo
for u in a0:owner a1:gm a2:fin b1:mgrBGS c1:ptLead c2:pt2both c3:ft d1:sbjC; do
  id=00000000-0000-0000-0000-0000000000${u%%:*}
  q="set role authenticated; select set_config('request.jwt.claim.sub','$id',false);"
  line="${u#*:}"
  for t in $TABLES; do
    n=$($P -c "$q" -c "select count(*) from public.$t" 2>&1 | tail -1)
    line="$line $t=$n"
  done
  echo "$line"
done
