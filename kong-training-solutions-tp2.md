# TP 3 : Authentification 

Slides de la formation

## Objectif du TP3
Authentification via une clé d'API

## Support de TP3
Pour réaliser le TP nous utiliserons:
* un docker-compose avec kong et le dashboard konga
* Dernière version de Kong et de konga

## l'authentification
L'authentification est le processus de vérification de l'identité du consommateur de la ressource.
Kong Gateway dispose d'une bibliothèque de plugins qui prennent en charge les méthodes d'authentification de passerelle API les plus largement utilisées.

Les méthodes d'authentification courantes incluent :
Key Authentication
Basic Authentication
OAuth 2.0 Authentication
LDAP Authentication Advanced
OpenID Connect


## 1: Activation de l'authentification
Dans Kong Gateway, un service est une abstraction d'une API existante. Les services peuvent stocker des collections d'objets tels que des configurations de plug-in et des stratégies, et ils peuvent être associés à des routes.
Lors de la définition d'un service, l'administrateur fournit un nom et les informations de connexion à l'upstream. 
Les services ont une relation un-à-plusieurs avec les applications en amont, ce qui permet aux administrateurs de créer des comportements sophistiqués de gestion du trafic.

Avec Kong Gateway contrôlant l'authentification, les demandes n'atteindront les services en amont que si le client s'est authentifié avec succès. 

Kong Gateway a une visibilité sur toutes les tentatives d'authentification, ce qui permet de créer des capacités de surveillance et d'alerte prenant en charge la disponibilité et la conformité des services.

### 1.1: Création d'un consommateur et d'une clé d'authentification


L'authentification par clé API est une méthode populaire pour appliquer l'authentification API. 
Avec l'authentification par clé, Kong Gateway est utilisé pour générer et associer une clé API à un consommateur. Cette clé est le secret d'authentification présenté par le client lors de demandes ultérieures. Kong Gateway approuve ou refuse les demandes en fonction de la validité de la clé présentée. Ce processus peut être appliqué globalement ou à des services et routes individuels.

Création d'un consommateur:
```
curl -i -X POST http://localhost:8001/consumers/ \
  --data username=luka
```

Assigner la clé à un consommateur d'API:
```
curl -i -X POST http://localhost:8001/consumers/luka/key-auth \
  --data key=top-secret-key
```

### 1.2: Clé d'authentication au niveau globale
L'installation du plug-in à l'échelle globale signifie que chaque demande de proxy adressée à Kong Gateway est protégée par une authentification par clé.

Activation de l'authentification key:
Le plugin Key Authentication est installé par défaut sur Kong Gateway et peut être activé en envoyant une requête POST à ​​la ressource plugins sur l'API Admin :
```
curl -X POST http://localhost:8001/plugins/ \
    --data "name=key-auth"  \
    --data "config.key_names=apikey"
...

Le champ de configuration key_names dans la requête ci-dessus définit le nom du champ que le plug-in recherche pour lire la clé lors de l'authentification des requêtes. Le plug-in recherche le champ dans les headers, les query params et payload de la requête.

```

### 1.3:Exemple de requête non authentifié ou avec une clé érronée
Sans clé:
```
curl -i http://localhost:8000/mock/request

HTTP/1.1 401 Unauthorized
...
{
    "message": "No API key found in request"
}
```
Avec clé erroné:
```
curl -i http://localhost:8000/mock/request \
  -H 'apikey:bad-key'
```

```
HTTP/1.1 401 Unauthorized
...
{
  "message":"Invalid authentication credentials"
}
```
Avec une clé valide
```
curl -i http://localhost:8000/mock/request \
  -H 'apikey:top-secret-key'
  ...
HTTP/1.1 200
```

### 1.4: Authentification par clé basée sur le service
```
   curl -X POST http://localhost:8001/services/example_service/plugins \
     --data name=key-auth
```

### 1.5 Authentification par clé basée sur la route
```
   curl -X POST http://localhost:8001/routes/example_route/plugins \
     --data name=key-auth
```

### 2 Désactivation d'un plugin
```
   curl -X GET http://localhost:8001/plugins/
```
Récupérer l'id du plugin pour le désactiver
```
   curl -X PATCH http://localhost:8001/plugins/2512e48d9-7by0-674c-84b7-00606792f96b \
  --data enabled=false
```
Test de désactivation
```
curl -i http://localhost:8000/mock/request
```
