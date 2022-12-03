# TP 1 : Getting started: Installation de Kong community / Services / Routes 

Slides de la formation

## Objectif du TP1
Installation de kong gateway community, création des services et gestion des routes Kong

## Support de TP1
Pour réaliser le TP nous utiliserons:
* un docker-compose avec kong et le dashboard konga
* Dernière version de Kong et de konga

## Installation via docker-compose de kong avec une base de donnée postgres et de konga dashboard

Pour activer la persistence dans la base de donnée, il faut exporter la variable d'env KONG_DATABASE à postgres
La valeur [ KONG_DATABASE = off ] permet de démarrer kong sans base de donnée avec une persistence de la configuration en mémoire.
``` 
https://github.com/Kuari/kong-konga-docker-compose
```

Pour vérifier que la gateway kong est démarée
```
 curl -i http://localhost:8001
```

## 1: Les services
Dans Kong Gateway, un service est une abstraction d'une API existante. Les services peuvent stocker des collections d'objets tels que des configurations de plug-in et des stratégies, et ils peuvent être associés à des routes.
Lors de la définition d'un service, l'administrateur fournit un nom et les informations de connexion à l'upstream. 

### 1.1: Création d'un service
Pour ajouter un service, envoyer une requête POST à l'API Kong Gateway’s Admin API /services:
```
curl -i -s -X POST http://localhost:8001/services \
  --data name=mockbin_service \
  --data url='http://mockbin.org'
```
Cet appel API demande à Kong Gateway de créer un nouveau service mappé à l'upstream http://mockbin.org. Payload de la requête :
nom : le nom du service
url : upstream


### 1.2: Vérification de la création du service
Reponse 201 de Kong Gateway confirmant que le service a été créé.
```
curl -i -s -X POST http://localhost:8001/services \
  --data name=mockbin_service \
  --data url='http://mockbin.org'
  
HTTP/1.1 201 Created
Date: Tue, 08 Nov 2022 10:46:28 GMT
Content-Type: application/json; charset=utf-8
Connection: keep-alive
Access-Control-Allow-Origin: *
Content-Length: 376
X-Kong-Admin-Latency: 43
Server: kong/3.0.0

{"tls_verify_depth":null,"host":"mockbin.org","name":"mockbin_service","retries":5,"id":"f60ccb21-8974-436e-80c7-2f5fc0a577f9","created_at":1667904388,"port":80,"client_certificate":null,"enabled":true,"ca_certificates":null,"connect_timeout":60000,"write_timeout":60000,"protocol":"http","updated_at":1667904388,"tags":null,"tls_verify":null,"read_timeout":60000,"path":null}
```

### 1.3: Vérification de configuration d'un service
On peut obtenir la configuration du service via 
```
curl -X GET http://localhost:8001/services/mockbin_service

{
  "host": "mockbin.org",
  "name": "mockbin_service",
  "enabled": true,
  ...
}
```
### 1.4: Mise à jour d'un service
```
curl --request PATCH \
  --url localhost:8001/services/mockbin_service \
  --data retries=6

{
  "host": "mockbin.org",
  "name": "mockbin_service",
  "enabled": true,
  "retries": 6,
  ...
}
```
### 1.5 Lister les services

```
curl -X GET http://localhost:8001/services
```

### 1.6 API docs pour Kong Admin API
https://docs.konghq.com/gateway/latest/admin-api/#update-service

## 2: Les routes
Une route est un chemin vers une ressource . Des routes sont ajoutées aux services pour permettre l'accès à l'application sous-jacente. Dans Kong Gateway, les routes sont généralement mappées aux endpoints qui sont exposés via l'application Kong Gateway. Les routes peuvent également définir des règles qui associent les demandes aux services associés.

Vous pouvez également configurer des routes avec :

Protocols : protocole utilisé pour communiquer avec l'application en amont.
Hosts : listes de domaines correspondant à une route
Methods : méthodes HTTP qui correspondent à une route
Headers : listes de valeurs attendues dans l'en-tête d'une requête
Redirect status codes : codes d'état HTTPS
Tags : ensemble facultatif de chaînes pour regrouper les itinéraires 

### 2.1 Création d'une route

Les routes définissent la manière dont les requêtes sont transmises par proxy par Kong Gateway. Vous pouvez créer une route associée à un service spécifique en envoyant une requête POST à ​​l'URL du service.
Configurez une nouvelle route /mock pour diriger le trafic vers le service mockbin_service créé précédemment :
```
curl -i -X POST http://localhost:8001/services/mockbin_service/routes \
  --data 'paths[]=/mock' \
  --data name=mockbin_route
HTTP/1.1 201 Created
Date: Tue, 08 Nov 2022 11:29:07 GMT
Content-Type: application/json; charset=utf-8
Connection: keep-alive
Access-Control-Allow-Origin: *
Content-Length: 485
X-Kong-Admin-Latency: 150
Server: kong/3.0.0
```
Si la route a été créée avec succès, l'API renvoie un code de réponse 201 et un corps de réponse comme celui-ci :
```
{"headers":null,"strip_path":true,"hosts":null,"name":"mockbin_route","id":"930c6f56-8039-40be-8fef-06f00f43eb8f","paths":["/mock"],"methods":null,"request_buffering":true,"created_at":1667906947,"updated_at":1667906947,"service":{"id":"f60ccb21-8974-436e-80c7-2f5fc0a577f9"},"path_handling":"v0","sources":null,"preserve_host":false,"snis":null,"destinations":null,"regex_priority":0,"tags":null,"https_redirect_status_code":426,"protocols":["http","https"],"response_buffering":true}
```
### 2.2  Récupérer la configuration d'une route
Lorsque vous créez une route, Kong Gateway lui attribue un identifiant unique, comme indiqué dans la réponse ci-dessus. Le champ id, ou le nom fourni lors de la création de la route, peut être utilisé pour identifier la route dans les requêtes ultérieures. L'URL de route peut prendre l'une des formes suivantes :
/services/{service name or id}/routes/{route name or id}
/routes/{route name or id}
```
curl -X GET http://localhost:8001/services/mockbin_service/routes/mockbin_route
```

### 2.3 Mettre à jour la configuration d'une route
Les routes peuvent être mises à jour dynamiquement en envoyant une requête PATCH à l'URL de la route.

Les tags sont un ensemble facultatif de labels qui peuvent être associées à la route pour le regroupement et le filtrage. Vous pouvez attribuer des balises en envoyant une demande PATCH au point de terminaison des services et en spécifiant une route.
```
curl --request PATCH \
  --url localhost:8001/services/mockbin_service/routes/mockbin_route \
  --data tags="tutorial"
```

### 2.4 Récupérer la liste des routes

```
curl http://localhost:8001/routes
```

### 2.5 API docs pour Kong Admin API
https://docs.konghq.com/gateway/latest/admin-api/#route-object

## Proxy une requête

```
curl -X GET http://localhost:8000/mock/requests
```