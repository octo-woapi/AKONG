# TP 3 : Getting started: Rate Limiting Service / Route / Consommateur

Slides de la formation

## Objectif du TP3
Rate Limiting

## Support de TP3
Pour réaliser le TP nous utiliserons:
* un docker-compose avec kong et le dashboard konga
* Dernière version de Kong et de konga

## le plugin Rate Limiting 
Rate Limiting est utilisée pour contrôler le débit des requêtes envoyées à un service en amont. Il peut être utilisé pour empêcher les attaques DoS, limiter le scraping Web et d'autres formes de brute force. Sans limitation de débit, les clients ont un accès illimité à vos services en amont, ce qui peut avoir un impact négatif sur la disponibilité.

Kong Gateway impose des limites de débit aux clients grâce à l'utilisation du plugin Rate Limiting. Lorsque la limitation du débit est activée, les clients sont limités dans le nombre de requêtes pouvant être effectuées dans une période de temps configurable. Le plugin prend en charge l'identification des clients en tant que consommateurs ou par l'adresse IP client des demandes.


## 1: Gestion de Rate limit
Dans Kong Gateway, un service est une abstraction d'une API existante. Les services peuvent stocker des collections d'objets tels que des configurations de plug-in et des stratégies, et ils peuvent être associés à des routes.
Lors de la définition d'un service, l'administrateur fournit un nom et les informations de connexion à l'upstream. Les détails de connexion peuvent être fournis dans le champ URL sous forme de chaîne unique ou en fournissant des valeurs individuelles pour le protocole, l'hôte, le port et la route.
Les services ont une relation un-à-plusieurs avec les applications en amont, ce qui permet aux administrateurs de créer des comportements sophistiqués de gestion du trafic.

### 1.1: Activation du rate limit
Le plugin de limitation de débit est installé par défaut sur Kong Gateway, et peut être activé en envoyant une requête POST à ​​l'objet plugins sur l'API Admin :

```
curl -i -X POST http://localhost:8001/plugins \
  --data name=rate-limiting \
  --data config.minute=5 \
  --data config.policy=local

config.policy => local =	Minimal performance impact.	Less accurate. Unless there’s a consistent-hashing load balancer in front of Kong, it diverges when scaling the number of nodes.	 
config.policy => cluster =	Accurate, no extra components to support.	Each request forces a read and a write on the data store. Therefore, relatively, the biggest performance impact.	 
config.policy => redis =	Accurate, less performance impact than a cluster policy.


HTTP/1.1 201 Created
Date: Tue, 08 Nov 2022 15:10:07 GMT
Content-Type: application/json; charset=utf-8
Connection: keep-alive
Access-Control-Allow-Origin: *
Content-Length: 599
X-Kong-Admin-Latency: 172
Server: kong/3.0.0

{"route":null,"config":{"limit_by":"consumer","redis_database":0,"second":null,"minute":5,"hour":null,"day":null,"month":null,"year":null,"policy":"local","fault_tolerant":true,"hide_client_headers":false,"redis_server_name":null,"redis_ssl_verify":false,"redis_username":null,"redis_password":null,"redis_host":null,"header_name":null,"redis_port":6379,"redis_timeout":2000,"redis_ssl":false,"path":null},"consumer":null,"service":null,"tags":null,"enabled":true,"created_at":1667920207,"id":"2ae705fc-1ae0-4740-a503-c890a1be3f11","name":"rate-limiting","protocols":["grpc","grpcs","http","https"]}
```
Cette commande a demandé à Kong Gateway d'imposer un maximum de 5 requêtes par minute par adresse IP client pour toutes les routes et tous les services.
La configuration de la politique détermine où Kong Gateway récupère et incrémente les limites.


### 1.2: Validation du bon fonctionnement du rate limit
Reponse 201 de Kong Gateway confirmant que le service a été créé.
```
for _ in {1..6}; do curl -s -i localhost:8000/mock/request --header 'apikey: top-secret-key'; echo; sleep 1; done
...
HTTP/1.1 429 Too Many Requests
Date: Tue, 08 Nov 2022 15:12:48 GMT
Content-Type: application/json; charset=utf-8
Connection: keep-alive

### Voir les headers du Rate limit rajouté par Kong

X-RateLimit-Remaining-Minute: 0
X-RateLimit-Limit-Minute: 5
RateLimit-Remaining: 0
RateLimit-Reset: 12
Retry-After: 12
RateLimit-Limit: 5


Content-Length: 41
X-Kong-Response-Latency: 3
Server: kong/3.0.0

{
  "message":"API rate limit exceeded"
}
```

### 1.3:Rate limit au niveau d'un service
Le plugin Rate Limiting peut être activé pour des services spécifiques. La requête est la même que ci-dessus, mais publiée sur l'URL du service :
```
curl -X POST http://localhost:8001/services/example_service/plugins \
   --data "name=rate-limiting" \
   --data config.minute=5 \
   --data config.policy=local
```
### 1.4: Rate limit au niveau de la route
```
curl -X POST http://localhost:8001/routes/example_route/plugins \
   --data "name=rate-limiting" \
   --data config.minute=5 \
   --data config.policy=local

```
### 1.5 Rate limiting au niveau d'un consommateur
Création d'un consommateur
```
curl -X POST http://localhost:8001/consumers/ \
  --data username=jsmith

curl -X POST http://localhost:8001/plugins \
   --data "name=rate-limiting" \
   --data "consumer.username=jsmith" \
   --data "config.second=5"

```