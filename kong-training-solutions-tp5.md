# TP 5 : OAuth2/openid 


Slides de la formation

## Objectif du TP5
S'authentifier avec de l'oauth2 / OIDC

## Support de TP5
Pour réaliser le TP nous utiliserons:
* un docker-compose avec kong et le dashboard konga
* Dernière version de Kong et de konga

## Le plugin jwt
Vérifie les demandes contenant des jetons Web JSON signés HS256 ou RS256 (comme spécifié dans la RFC 7519). Chacun de vos consommateurs aura des informations d'identification JWT (clés publiques et secrètes), qui doivent être utilisées pour signer leurs JWT. Un jeton peut alors être transmis :

- dans un cookie
- query string
- header
Kong transmettra la demande à vos services en amont si la signature du jeton est vérifiée ou rejettera la demande si ce n'est pas le cas. Kong peut également effectuer des vérifications sur certaines claims enregistrées de la RFC 7519.


## 1: Activation du plugin jwt

Pour utiliser le plugin, vous devez d'abord créer un consommateur et lui associer un ou plusieurs identifiants JWT (contenant les clés publiques et privées utilisées pour vérifier le jeton). Le Consommateur représente un développeur utilisant le service final.

### 1.1: Activation au niveau d'un service

```
curl -X POST http://localhost:8001/services/SERVICE_NAME|SERVICE_ID/plugins \
    --data "name=jwt" 
```

### 1.2: Activation au niveau d'une route

```
curl -X POST http://localhost:8001/routes/mockbin_rt/plugins \
  --data "name=jwt" 
```

### 1.3: Activation au niveau globale

```
curl -X POST http://localhost:8001/plugins/ \
  --data "name=jwt" 
```

### 1.4: Création d'un consumer

```
curl -d "username=user123&custom_id=SOME_CUSTOM_ID" http://localhost:8001/consumers/
```

### 1.5: Création d'un credentiel jwt 

```
curl -X POST http://localhost:8001/consumers/CONSUMER/jwt -H "Content-Type: application/x-www-form-urlencoded"

HTTP/1.1 201 Created

{"consumer":{"id":"855e5f5c-bc0a-448b-9ff8-077b378e564a"},"secret":"yMS7vYRVqVLoYIDn5wDhd0GSp7K9q0oC","rsa_public_key":null,"key":"6HORAA4RnEyebsdUXFrPuSANsKVpsekh","id":"2e7266fb-a414-41b5-bd62-9281d6b80722","created_at":1668032224,"tags":null,"algorithm":"HS256"}

```

Pour supprimer le jwt plugin
```
curl -X DELETE http://localhost:8001/consumers/{consumer}/jwt/{id}
```

Pour lister les jwt credentiels
```
curl -X GET http://localhost:8001/consumers/{consumer}/jwt
```


Exemple:

curl -X GET http://localhost:8000/mockk/requests -H "Authorization:Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJpc3MiOiI2SE9SQUE0Um5FeWVic2RVWEZyUHVTQU5zS1Zwc2VraCJ9.7zgUmrjYOmDgmLgkuy1k3gSiRuYfZso4puMWkYrEL-Y"

{
  "startedDateTime": "2022-11-09T22:26:05.786Z",
  "clientIPAddress": "192.168.0.1",
  "method": "GET",
  "url": "http://localhost/requests",
  "httpVersion": "HTTP/1.1",
  "cookies": {},
  "headers": {
    "host": "mockbin.org",
    "connection": "close",
    "accept-encoding": "gzip",
    "x-forwarded-for": "192.168.0.1,89.95.60.200, 172.71.122.111",
    "cf-ray": "7679f7d14efdd526-CDG",
    "x-forwarded-proto": "http",
    "cf-visitor": "{\"scheme\":\"http\"}",
    "x-forwarded-host": "localhost",
    "x-forwarded-port": "80",
    "x-forwarded-path": "/mockk/requests",
    "x-forwarded-prefix": "/mockk",
    "user-agent": "curl/7.79.1",
    "accept": "*/*",
    "authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJpc3MiOiI2SE9SQUE0Um5FeWVic2RVWEZyUHVTQU5zS1Zwc2VraCJ9.7zgUmrjYOmDgmLgkuy1k3gSiRuYfZso4puMWkYrEL-Y",
    "x-consumer-id": "855e5f5c-bc0a-448b-9ff8-077b378e564a",
    "x-consumer-custom-id": "SOME_CUSTOM_ID",
    "x-consumer-username": "user123",
    "x-credential-identifier": "6HORAA4RnEyebsdUXFrPuSANsKVpsekh",
    "cf-connecting-ip": "89.95.60.200",
    "cdn-loop": "cloudflare",
    "x-request-id": "49e5f459-7da3-4822-9428-94632b3f0e25",
    "via": "1.1 vegur",
    "connect-time": "0",
    "x-request-start": "1668032765780",
    "total-route-time": "0"
  },
  "queryString": {},
  "postData": {
    "mimeType": "application/octet-stream",
    "text": "",
    "params": []
  },
  "headersSize": 1007,
  "bodySize": 0
}


### 1.6: Sécuriser avec le plugin JWT et Oauth0

Création d'un service
```
curl -i -f -X POST http://localhost:8001/services \
  --data "name=demo-jwt" \
  --data "url=http://httpbin.org"
```

Création d'une route
```
curl -i -f -X POST http://localhost:8001/routes \
  --data "service.id=5c9ab3fc-7d4f-4ce0-b268-95b97bec1ee1" \
  --data "paths[]=/route-demo-jwt"
```

Ajouter le plugin JWT
```
curl -X POST http://localhost:8001/routes/75d67d92-8fcd-43ab-abb4-7d80204bc173/plugins \
  --data "name=jwt"
```

Générer la public key de Oauth0
```
curl -o kong-training.pem https://kong-training.eu.auth0.com/pem
```

Extraire la clé publique du certificat X509
```
openssl x509 -pubkey -noout -in kong-training.pem > pubkey.pem
```

Créer un consummer avec la clé publique de OAuth0
```
curl -i -X POST http://localhost:8001/consumers \
  --data "username=alice" \
  --data "custom_id=aliceID"

curl -i -X POST http://localhost:8001/consumers/5ed09023-8662-489d-8b4e-4d6a1babbd94/jwt \
  -F "algorithm=RS256" \
  -F "rsa_public_key=@./pubkey.pem" \
  -F "key=https://kong-training.auth0.com/" # the `iss` field
```

Le plug-in JWT valide par défaut le key_claim_name par rapport au champ iss du jeton. Les clés émises par Auth0 ont leur champ iss défini sur http://{COMPANYNAME}.auth0.com/. 
jwt.io pour valider le champ iss pour le paramètre key lors de la création du Consumer.

Seuls les jetons signés par Auth0 fonctionneront :

Générer un jeton avec OAUTH0
```
curl --request POST \
  --url https://kong-training.eu.auth0.com/oauth/token \
  --header 'content-type: application/json' \
  --data '{"client_id":"LRRBB87zPY13hUYO8LOcixNc06Uval3r","client_secret":"we_ZBMMY_5ljOAy563tXohE96vvAT3zkhakTtPVwOt7EVevx5DS52rZjpugXP9CR","audience":"https://kong-training.eu.auth0.com/api/v2/","grant_type":"client_credentials"}'
```

```
curl -X GET http://localhost:8000/route-demo-jwt/get -H "Authorization:Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJlZG9raWFsIiwic3ViIjoiMTIzNDU2Nzg5MCIsIm5hbWUiOiJKb2huIERvZSIsImlhdCI6MTUxNjIzOTAyMn0.NGjteQe9scav73HLHyZVQELYG1eAcMpQ3HuJv0pq1uE"
{
  "args": {},
  "headers": {
    "Accept": "*/*",
    "Authorization": "Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6IjJZMk5yV2VyNzBrTEh2MVpoRGxleCJ9.eyJpc3MiOiJodHRwczovL2tvbmctdHJhaW5pbmcuZXUuYXV0aDAuY29tLyIsInN1YiI6IkxSUkJCODd6UFkxM2hVWU84TE9jaXhOYzA2VXZhbDNyQGNsaWVudHMiLCJhdWQiOiJodHRwczovL2tvbmctdHJhaW5pbmcuZXUuYXV0aDAuY29tL2FwaS92Mi8iLCJpYXQiOjE2NjkwMzM4MTAsImV4cCI6MTY2OTEyMDIxMCwiYXpwIjoiTFJSQkI4N3pQWTEzaFVZTzhMT2NpeE5jMDZVdmFsM3IiLCJndHkiOiJjbGllbnQtY3JlZGVudGlhbHMifQ.sk8PNCBZEC1XgXuQmLzJAUy7CKEDR3Nafmxdz3fiFjF9oa57z1-_3cmIqppAHyJBSvoIbzZr5K8a8cvjTXS7V2YOz6wsnI3-ow6zTarwIa6PBdVFb-Y10XnlogCNjMHN6FMwREZiIFkaT_L3vxXN88ONHnYTO2_ieUBUGzHDDCU7C_EpJFZH9cKlE6dKh72MulkIC6ecSY19-E8CrF-_M-wgFIG0qw2p9dUM4qGq5lNSugA2l1mX_tS1ogwl2w1-LhihXd5BYtGCYQaZ4vPWR1L4Pd-jlqa_ef7L7d-9S_bKiUXd3Ru414qZXdu30ZhgXL-DQfnXXz8WV-5hGmrtag",
    "Host": "httpbin.org",
    "User-Agent": "curl/7.79.1",
    "X-Amzn-Trace-Id": "Root=1-637b7203-69b905fa4edb1299776e3a07",
    "X-Consumer-Custom-Id": "yyahya",
    "X-Consumer-Id": "1cc13b95-d8bb-43e8-b4b3-699361c192b8",
    "X-Consumer-Username": "youyou",
    "X-Credential-Identifier": "https://kong-training.eu.auth0.com/",
    "X-Forwarded-Host": "localhost",
    "X-Forwarded-Path": "/jwt_path/get",
    "X-Forwarded-Prefix": "/jwt_path"
  },
  "origin": "192.168.0.1, 89.95.60.200",
  "url": "http://localhost/get"
}
```

/**
securiser avec oauth2
gateway verifie la presence du jwt , issuer , signature (custom  exp, nlp ... ) 
gateway = vérifie la clé publique 
Pas besoin d'introspect 
invalidation des tokens = duree courte
https://docs.konghq.com/gateway/latest/production/running-kong/secure-admin-api/#kong-api-loopback ( bloquer le port et faire port forward )
kong api loopback secure admin api with kong 
*/

jwks plugin payant permet de valider via un endpoint jwks_uri