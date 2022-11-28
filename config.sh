service_name='monService'
service_url='http://mockbin.org/bin/a63a0c40-b73b-40c8-8d17-b97f847911d2'

# CRÉATION DU SERVICE
curl -i -X POST \
--url http://localhost:8001/services/ \
--data 'name=monService' \
--data 'url=http://mockbin.org/bin/a63a0c40-b73b-40c8-8d17-b97f847911d2/api'

# AJOUT D'UNE PREMIÈRE ROUTE
curl -i -X POST \
--url 'http://localhost:8001/services/monService/routes' \
--data 'id=0FCDE23B-FFA0-424D-A4C0-BBF6EED566C0' \
--data 'hosts[]=localhost' \
--data 'paths[]=/openbar' \
--data 'methods[]=GET' \
--data 'methods[]=OPTIONS'

# AJOUT D'UNE DEUXIÈME ROUTE
curl -i -X POST \
--url 'http://localhost:8001/services/monService/routes' \
--data 'id=C5FADFE7-EC2A-42D2-901F-FD1F97BA11BD' \
--data 'hosts[]=localhost' \
--data 'paths[]=/ratelimited' \
--data 'methods[]=GET' \
--data 'methods[]=OPTIONS'


# ACTIVER LE PLUGIN KEY AUTH SUR LE SERVICE POUR L'API KEY
curl -X POST http://localhost:8001/services/monService/plugins \
    --data "name=key-auth"  \
    --data 'config.run_on_preflight=false' \
    --data "config.key_names=X-API-KEY" \
    --data "config.key_in_header=true"

# ACTIVER LE PLUGIN KEY AUTH SUR LA ROUTE RATE LIMITED
curl -X POST http://localhost:8001/routes/C5FADFE7-EC2A-42D2-901F-FD1F97BA11BD/plugins \
    --data "name=key-auth"  \
    --data "config.key_names=Referer" \
    --data 'config.run_on_preflight=false' \
    --data "config.key_in_header=true"

# CRÉER UN CONSOMMATEUR
curl http://localhost:8001/consumers/ \
    --data "username=consumer-front"
# CRÉER UN CONSOMMATEUR
curl http://localhost:8001/consumers/ \
    --data "username=consumer-batch"

# AJOUTER UNE API KEY
curl -X POST http://localhost:8001/consumers/ConsumerFrontEnd/key-auth \
    --data "key=CLE-FRONT"
curl -X POST http://localhost:8001/consumers/consumer-front/key-auth \
    --data "key=localhost"
curl -X POST http://localhost:8001/consumers/consumer-front/key-auth \
    --data "key=http://localhost:63342/"
curl -X POST http://localhost:8001/consumers/consumer-batch/key-auth \
    --data "key=CLE-BATCH"

# RATE LIMITING
curl -X POST http://localhost:8001/routes/C5FADFE7-EC2A-42D2-901F-FD1F97BA11BD/plugins \
    --data "name=rate-limiting"  \
    --data "config.minute=6" \
    --data "config.policy=local"

# GROUPS
curl -X POST http://localhost:8001/consumers/consumer-front/acls \
    --data "group=group-ratelimited"

curl -X POST http://localhost:8001/consumers/consumer-batch/acls \
    --data "group=group-openbar"

# ACL
# RATE LIMITED
curl -X POST http://localhost:8001/routes/C5FADFE7-EC2A-42D2-901F-FD1F97BA11BD/plugins \
    --data "name=acl"  \
    --data "config.allow=group-ratelimited" \
    --data "config.hide_groups_header=true"

# OPEN BAR
curl -X POST http://localhost:8001/routes/0FCDE23B-FFA0-424D-A4C0-BBF6EED566C0/plugins \
    --data "name=acl"  \
    --data "config.allow=roup-openbar" \
    --data "config.hide_groups_header=true"

# CORS
curl -X POST http://localhost:8001/plugins/ \
    --data "name=cors"  \
    --data "enabled=true"  \
    --data "config.origins=*" \
    --data "config.headers=x-api-key" \
    --data "config.max_age=3600" \
    --data "config.preflight_continue=false"
