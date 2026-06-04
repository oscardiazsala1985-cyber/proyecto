# SRE Process Service - AWS Serverless Terraform

Infraestructura serverless para recibir solicitudes HTTP, procesarlas en Lambda, persistir resultados en S3 y usar Redis como caché.

## Arquitectura

```mermaid
flowchart LR
  C[Cliente HTTP] --> APIGW[API Gateway HTTP API\nPOST /process]
  APIGW --> L[Lambda en subnets privadas]
  L --> R[(ElastiCache Redis\nsubnets privadas)]
  L -->|Gateway VPC Endpoint| S3[(S3 privado versionado)]
  L -->|egress controlado| NAT[NAT Gateway]
  NAT --> IGW[Internet Gateway]
**
Decisiones de diseño

    HTTP API: se usa por menor costo y menor latencia frente a REST API para una ruta simple con integración proxy Lambda.

    Lambda en VPC privada: cumple el aislamiento solicitado y permite comunicación privada con Redis.

    Redis cache.t3.micro: opción económica válida para una prueba técnica.

    S3 Gateway VPC Endpoint: el acceso privado a S3 se enruta desde las tablas privadas sin salir a internet.

    Security Groups segmentados: Redis solo acepta TCP/6379 desde el SG de Lambda; Lambda solo tiene egress a Redis/6379 y HTTPS.

Pre-requisitos

    Herramientas y Versiones:

        Terraform v1.5.0 o superior.

        AWS CLI v2.

        Node.js 20.x (entorno de ejecución de la Lambda).

    Permisos AWS:
    El perfil de AWS configurado para ejecutar Terraform debe contar con permisos suficientes para aprovisionar infraestructura. Se recomienda un rol con AdministratorAccess para entornos de prueba, o como mínimo, las siguientes políticas gestionadas:

        AmazonVPCFullAccess

        AmazonAPIGatewayAdministrator

        AWSLambda_FullAccess

        AmazonS3FullAccess

        AmazonElastiCacheFullAccess

        IAMFullAccess (para la creación del rol de ejecución de la Lambda)

Despliegue
Bash

terraform init
terraform plan
terraform apply -auto-approve

Verificación end-to-end

Obtén el endpoint y el bucket:
Bash

API_URL=$(terraform output -raw api_process_url)
BUCKET=$(terraform output -raw results_bucket_name)

Primera llamada, debe retornar X-Cache: MISS:
Bash

curl -i -X POST "$API_URL" \
  -H 'Content-Type: application/json' \
  -d '{"customerId":"123","amount":100}'

Segunda llamada idéntica, antes de 60 segundos, debe retornar X-Cache: HIT:
Bash

curl -i -X POST "$API_URL" \
  -H 'Content-Type: application/json' \
  -d '{"customerId":"123","amount":100}'

Validar objeto en S3:
Bash

aws s3 ls "s3://$BUCKET/results/$(date +%F)/" --recursive

Las capturas de pantalla de esta verificación se encuentran en la carpeta evidence/ de este repositorio.
Limpieza
Bash

terraform destroy