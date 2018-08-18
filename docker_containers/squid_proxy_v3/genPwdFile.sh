OUTFILE=$1
USER=$2
PASSWORD=$3
REALM=$4

DIGEST="$( printf "%s:%s:%s" "$USER" "$REALM" "$PASSWORD" | md5sum | awk '{print $1}' )"

printf "%s:%s:%s\n" "$USER" "$REALM" "$DIGEST" >> "$OUTFILE"
