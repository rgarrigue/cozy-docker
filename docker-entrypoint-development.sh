#!/bin/sh
# set -x



echo "=========================================================================="
echo "Starting $0, $(date)"
echo "=========================================================================="


echo "Starting CouchDB, Redis & MailHog localy..."
couchdb &> /var/log/couchdb.log &
redis &> /var/log/redis.log &
MailHog &> /var/log/mailhog.log &

echo "Wait for CouchDB to be available..."
wait-for-it.sh -h localhost -p 5984 -t 60

echo "Init CouchDB databases, nothing will happen if they already exists..."
for db in _global_changes _metadata _replicator _users
do
  curl -s -X PUT "http://localhost:5984/$db"
done

echo "Wait for Redis to be available..."
wait-for-it.sh -h localhost -p 6379 -t 60

echo "Wait for MailHog to be available..."
wait-for-it.sh -h localhost -p 8045 -t 60



# Generate passphrase if missing
if [ ! -f /var/lib/stack/stack-admin-passphrase ]
then
  if [ -z "$STACK_ADMIN_PASSPHRASE" ]
  then
    echo "Using default admin passphrase !!!"
    STACK_ADMIN_PASSPHRASE="stack"
  fi
  echo "Generating /var/lib/stack/stack-admin-passphrase..."
  echo $STACK_ADMIN_PASSPHRASE | stack config passwd /var/lib/stack/stack-admin-passphrase
fi



# Prepare stepping down from root to applicative user with chosen UID/GID
USER_ID=${LOCAL_USER_ID:-36000}
GROUP_ID=${LOCAL_GROUP_ID:-36000}
groupadd -g $GROUP_ID -o stack
useradd --shell /bin/bash -u $USER_ID -g stack -o -c "Stack user" -d /var/lib/stack -m stack
chown -R stack: /var/lib/stack



# If running an applicative subcommand, running it as stack user
if echo "$@" | grep -q "stack "
then
  # Then run the command itself as applicative user
  echo "Now running CMD with UID $USER_ID and GID $GROUP_ID"
  exec gosu stack "$@"



else
  # Otherwise run the command as root
  exec "$@"
fi
