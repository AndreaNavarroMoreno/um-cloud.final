#!/bin/bash


echo "Instalando paquetes necesarios"

#sudo apt-get update
sudo apt-get install -y virtualbox
sudo apt-get install -y curl git-core
sudo apt-get install -y jq

echo "Instalando docker"
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
sudo apt-add-repository 'deb https://apt.dockerproject.org/repo ubuntu-xenial main'
sudo apt-get update
sudo apt-get install -y docker-engine



echo "Instalando kubectl"
(set -x; test -x /usr/local/bin/kubectl || curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl)

echo "Instalando  minikube"
(set -x; test -x /usr/local/bin/minikube || ( curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.16.0/minikube-linux-amd64 && chmod +x minikube && sudo mv minikube /usr/local/bin/ ) )


echo "Iniciando docker"
systemctl start docker

echo "Iniciando minikube"
minikube start

echo "Descargando Dockerfile y yaml temporal:"
git clone https://github.com/AndreaNavarroMoreno/um-cloud.final
cd um-cloud.final/

echo "Descargando imagen docker de ubuntu"
docker pull ubuntu:16.04

echo "Descargando bluemix"
(set -x; test -d php-mysql || git clone https://github.com/IBM-Bluemix/php-mysql.git)

echo "Creando registry local"
docker run -d -p 5000:5000 --restart=always --name registry registry:2

eval $(minikube docker-env)

echo "Creando la app"

APP_TAGS=mybluemix:latest

(set -x; 
docker build -t ${APP_TAGS} .
)
echo "Listo: ${APP_TAGS}"


: ${registry:="localhost"}
set -x
docker tag ${APP_TAGS} localhost:5000/${APP_TAGS}
docker push localhost:5000/${APP_TAGS}

echo "Levantando app"

sed -e "s/@EDITAR_USUARIO@/${USER}/" myappsql-rc.tmpl.yaml > /tmp/myappsql-rc-${USER}.yaml || exit 1
set -x
kubectl create -f /tmp/myappsql-rc-${USER}.yaml

APP_TAGS=mybluemix-svc

echo "Listo!"

echo "Obteniendo IP:"
minikube service mybluemix-svc --url
echo "LISTO! Por favor ingrese en -> $(minikube service mybluemix-svc --url)/php-mysql"
