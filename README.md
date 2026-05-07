# IaC - LAMBDA INTEGRATION
Este proyecto implementa una arquitectura Serverless y Event-Driven en AWS para el procesamiento asíncrono de imágenes. La infraestructura se define completamente como código (IaC) utilizando Terraform y cumple con altos estándares de seguridad (aislamiento de red, endpoints privados y principio de menor privilegio).

## 📋 Descripción
La aplicación expone una API pública que permite a los clientes subir imágenes. Las imágenes son almacenadas en un bucket S3 privado, lo que dispara un evento hacia una cola SQS. Finalmente, una función Lambda en una red privada (VPC) consume los mensajes, recorta la imagen aplicando una máscara circular y la guarda en una carpeta de procesados.

## 🛠️ Requisitos
Antes de desplegar, asegúrate de tener instalado en tu sistema:

- Terraform

- AWS CLI

- Node.js

## ⚙️ Configuración previa

### 1. Autenticación de AWS (SSO)
Este proyecto requiere un perfil de AWS SSO configurado localmente llamado `lmarinosdev` (Se puede modificar el nombre del perfil). 

Inicializa el SSO ejecutando en la terminal:

aws configure sso

-    **SSO start URL:** Ingresa la URL proporcionada por tu administrador.
-    **SSO region:** `us-east-2` (o la región de tu portal).
-    **CLI default client Region:** `us-east-1`
-    **CLI default output format:** `json`
-   **CLI profile name:** `lmarinosdev`.

Si ya lo tienes configurado, simplemente renueva tu sesión:

aws sso login --profile lmarinosdev


### 2. Archivo de variables
Por motivos de seguridad, el archivo de variables reales no se incluye en el control de versiones. Antes de desplegar, debes crear un archivo llamado `"nombre_entorno".tfvars` en la carpeta `iac/`.

Crea el archivo `iac/"nombre_entorno".tfvars` guiándote de este ejemplo:

iac/dev.tfvars

entorno   = "dev" ("prod", "qa")          
region    = "us-east-2"( o la region de uso)   

Esto creamos para cada uno de los entornos siguiendo esa plantilla

### 3. Terraform Workspaces
Este proyecto utiliza Workspaces de Terraform para separar los estados de diferentes entornos.

Antes de ejecutar el plan, crea o selecciona el workspace correspondiente a tu entorno:

- Para crear un nuevo workspace

    terraform workspace new "nombre_entorno"

- Si el workspace ya existe, selecciónalo:

    terraform workspace select "nombre_entorno"

## 🚀 Guía de Despliegue Paso a Paso
Paso 1: Preparar el código de las Lambdas (¡Muy Importante!)
Las dependencias de Node.js deben ser instaladas antes de ejecutar Terraform para que puedan ser empaquetadas correctamente.

- Instalar dependencias para la Lambda de Upload:

    cd src/upload-lambda

    npm install

    Instalar dependencias para la Lambda de Crop. 
    
    Como esta Lambda utiliza la librería sharp y se ejecutará en AWS (Linux), debes forzar la instalación de los binarios para Linux, independientemente de si usas Windows o Mac


    cd ../crop-lambda

    npm install --force --os=linux --cpu=x64 --libc=glibc

Paso 2: Despliegue con Terraform
Una vez que el código fuente esté listo y estés autenticado en AWS, procede con el despliegue de la infraestructura:

Navega a la carpeta de infraestructura:

cd ../../iac

Inicializa Terraform y descarga los proveedores:


terraform init

Revisa el plan de ejecución

terraform plan

Aplica los cambios para crear la infraestructura en AWS:

terraform apply

Al finalizar, Terraform imprimirá en la consola los Outputs.

## 🧪 Pruebas 
Para probar la infraestructura, realiza una petición POST enviando una imagen mediante multipart/form-data a la URL generada en los outputs de Terraform.

Ejemplo usando curl:

  curl.exe -X POST "api-id" -H "Content-Type: multipart/form-data" -F "file=@./imagen.jpg"

api-id se mostrará como output al hacer el apply.

## 💀 Destruccion de recursos
Luego de realizar las pruebas respectivas se deben de destruir los recursos creados para evitar cargos adicionales.

cd iac

terraform destroy