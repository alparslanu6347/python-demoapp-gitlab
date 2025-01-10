# python-demoapp-gitlab

- GitLab Server assigns pipeline jobs to available Runners, gitlab.com manages instances. GitLab offers multiple Runners also maintained by GitLab, these are available to all users on gitlab.com

In this hands-on we do not need to have any congiguration, we will use free features


# Part-1 :Create gitlab project/repository ``python-demoapp-gitlab``

- Go to gitlab

- Create gitlab project/repository
    Click `+` --> Select `New project/repository` -->> Click `Create blank project`
    `Project name` : `python-app`
    `Project URL`  : `https://gitlab.com/arrowlevent/python-demoapp-gitlab`
    `Visibility level` : `Public`
    `Project Configurations` : Put check mark on the `Initialize repository with a README`
    Click `Create project`


# Part-2 : Prepare `.gitlab-ci.yml`
- Go to gitlab
    - Click and get into your project/repository `python-demoapp-gitlab` --> Click `+` Select ``New file` from the list
    `filename` : `.gitlab-ci.yml`
    copy-paste into this file

***Burada sadece `before_script:` kullanımını göstermek için bu image kullandım, aslında bu uygulama için `python:3.8-alpine` yeterli olurdu ama o zaman da `before_script:` kısmında yazan komutu kullanamazdın*** 

```yaml (.gitlab-ci.yml)
run_test:
  variables:
    JOB__TEST_VAR: "LEVENT"
  image: python:3.9-slim-buster # This image has `Python and pip pre-installed`, and it will serve as the Runner's image to run the Python application. Otherwise, GitLab by default starts Runners with a `Ruby-based` image. You can use the image name from the Dockerfile.
  before_script:
    - apt-get update # The container we use to deploy the application (the Runner container that will run from the image mentioned above) is included within this setup.
  script:
    - python --version
    - pip3 --version
    - echo This job does not need any variables
    - echo "Hello my variable is '$JOB__TEST_VAR'"
    - pwd
    - ls
    - whoami
```

- Click `Commit changes`

- You can monitor the pipeline stages/jobs from here : `Build` -- `Pipelines`


# Part-2: Dockerfile and app.py

- python-demoapp-gitlab/ `+` ==>> Click `+` Select ``New file` from the list
    `filename` : `app.py`
    copy-paste into this file

```py   (app.py)
from http.server import BaseHTTPRequestHandler, HTTPServer

class MyHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        self.wfile.write(b'''
          ##         .
    ## ## ##        ==
 ## ## ## ## ##    ===
/"""""""""""""""""\___/ ===
{                       /  ===-
\______ O           __/
 \    \         __/
  \____\_______/


Hello from Docker!
''')

def run():
    print('Starting server...')
    server_address = ('', 8080)
    httpd = HTTPServer(server_address, MyHandler)
    print('Server started!')
    httpd.serve_forever()

if __name__ == '__main__':
    run()
```

- Click `Commit changes`


- python-demoapp-gitlab/ `+` ==>> Click `+` Select ``New file` from the list
    `filename` : `Dockerfile`
    copy-paste into this file

```Dockerfile
FROM python:3.8-alpine

RUN mkdir /app

ADD . /app

WORKDIR /app

EXPOSE 8080

CMD ["python3", "app.py"]
```
- Click `Commit changes`


# Part-3 : Modify `.gitlab-ci.yml` build image

- Pipeline hazırlamadan önce pipeline içinde kullanacağımız `sensitive` veya `sensitive olmayan` variables tanımlaması :
  Sensitive olan için ayrıca `Mask variable` EKLİYORUZ. Sensitive olmaya variable'ı pipeline içine de yazabiliriz.
   - `Settings` --> `CI/CD` --> `Variables` - `Expand` --> `Add variable` ==> `Key` : `DOCKER_HUB_USER`
                                                                          ==> `Value` : `alparslanu6347`  ***write yours*** 
                                                                                                          --> Click `Add variable`
                                                                          ==> `Type` : `Default`
                                                                          ==> `Environment` : `Default`
                                                       --> `Add variable` ==> `Key` : `DOCKER_HUB_PWD`
                                                                          ==> `Value` : `************`  ***write yours***
                                                                          ==> `Type` : `Default`
                                                                          ==> `Environment` : `Default`
                                                                          İLAVE OLARAK put check mark `Mask variable` --> Click `Add variable`

***Use `docker in docker`***
- [https://hub.docker.com/_/docker]
- [https://docs.gitlab.com/ee/ci/docker/using_docker_build.html]

- Click `.gitlab-ci.yml` -->> `Edit` -->> `Edit single file` --> copy-paste

```yaml (.gitlab-ci.yml)
variables:
  IMAGE_NAME: alparslanu6347/python-app-gitlab  
  IMAGE_TAG: python-demo-1.0

run_test:
  image: python:3.8-alpine # bu image içinde python ve pip kurulu, içinde python application çalışacak Runner'ın image'i, yoksa gitlab deafult olarak Runner'ları ruby image'dan ayağa kaldırır. Dockerfile içerisindeki image ismini kullanabilirsin
  script:
    - python --version
    - pip3 --version
    - pwd
    - whoami

build_image:
#   variables:      BURADA DA OLABİLİR BAŞTA DA
#     IMAGE_NAME: alparslanu6347/python-app-gitlab  
#     IMAGE_TAG: python-demo-1.0
  image: docker:24.0.5    # Runner içinde docker komutları koşması için docker kurulu bir container/image lazım, "docker in docker"
  services:
    - docker:24.0.5-dind
  variables:
    DOCKER_TLS_CERTDIR: "/certs"
  before_script:
    - docker login -u $DOCKER_HUB_USER -p $DOCKER_HUB_PWD  
  script:  
    - docker build -t $IMAGE_NAME:$IMAGE_TAG .
    - docker push $IMAGE_NAME:$IMAGE_TAG
```
- Click `Commit changes`
- Pipeline aşamalarını/joblarını buradan gözlemleyebilirsin `Build` -- `Pipelines`


# Part-4 : Modify `.gitlab-ci.yml` stage by stage

- Click `.gitlab-ci.yml` -->> `Edit` -->> `Edit single file` --> copy-paste

```yaml (.gitlab-ci.yml)
variables:
  IMAGE_NAME: alparslanu6347/python-app-gitlab  
  IMAGE_TAG: python-demo-1.0

stages:
  - test
  - build

run_test:
  stage: test
  image: python:3.8-alpine 
  script:
    - python --version
    - pip3 --version
    - pwd
    - whoami

build_image:
  stage: build
  image: docker:24.0.5 
  services:
    - docker:24.0.5-dind
  variables:
    DOCKER_TLS_CERTDIR: "/certs"
  before_script:
    - docker login -u $DOCKER_HUB_USER -p $DOCKER_HUB_PWD  
  script:  
    - docker build -t $IMAGE_NAME:$IMAGE_TAG .
    - docker push $IMAGE_NAME:$IMAGE_TAG
```
- Click `Commit changes`
- Pipeline aşamalarını/joblarını buradan gözlemleyebilirsin `Build` -- `Pipelines`


# Part-5 : Modify `.gitlab-ci.yml` deploy application

- Uygulamayı `docker container` kullanarak deploy edebileceğimiz server için `AWS Management Console` üzerinde 1 adet `Ubuntu 20.04 t2.micro` ec2-instance ayağa kaldır. Gitlab pipeline çalıştırınca uygulama AWS Cloud'da ubuntu ec2-instance içinde `contaner port 8080` üzerinden yayın yapacak

- Gitlab'ın bunu yapabilemesi için ssh ile bağlanması lazım, yani lokalimizdeki private key içeriğini gitlab'a variable olarak tanıtacağız. Bunun yerine her zaman kullandığım key-pair yerine (sadece bu uygulamaya yönelik, uygulama çalıştıktan sonra silmek üzere) yeni bir tane lokalde oluşturup public kısmını `arrow-gitlab.pub --> arrow-gitlab` AWS'e import et, private kısmını `arrow-gitlab -->> arrow-gitlab.pem` gitlab'a variable olarak tanıt.

```bash (pwd : .ssh)    (Your Local)
ssh-keygen
ls      # arrow-gitlab  arrow-gitlab.pub

cat arrow-gitlab.pub    # BUNUN İÇERİĞİ AWS'E IMPORT EDİLECEK
### ***AWS'e import ederken ismine .pub kısmını yazma, sadece arrow-gitlab yaz***
### ***arrow-gitlab.pub'ı lokalinden silebilirsin gerek yok artık, sadece AWS'de kalsın.
rm arrow-gitlab.pub

ls  # arrow-gitlab
cat arrow-gitlab        # BUNUN İÇERİĞİ GitLab'a sensitive variable olarak girilecek
# key'e uzantı ekle aws instance'a ssh bağlantı yaparken dosya ismi arrow-gitlab.pem olmalı
mv arrow-gitlab arrow-gitlab.pem
ls  # arrow-gitlab.pem
```

- Launch an AWS EC2 instance of Ubuntu 20.04 `t2.micro` with security group allowing ``SSH:22``, ``HTTP:80`` and ``TCP 8080`` ports.
- Make a remote-ssh VSC connection to your instance

```bash (pwd : .ssh)    (Your Local)
ssh -i arrow-gitlab.pem ubuntu@ec2-44-211-225-205.compute-1.amazonaws.com
```

- install docker

```bash (pwd : home/ubuntu)
sudo apt update
sudo apt  install docker.io

# Check if the docker service is up and running.
systemctl status docker

### IF THE RESULT OF `systemctl status docker` COMMAND IS `PASSIVE` Execute these two commands below
# Start docker service. 
sudo systemctl start docker
# Enable docker service so that docker service can restart automatically after reboots.
sudo systemctl enable docker

# Again check if the docker service is up and running.
systemctl status docker

# add ubuntu into docker group, first check if the docker group exists
grep docker /etc/group      #  docker:x:120:  docker grubu oluşmuş
# if it doesn't already exist establish the Docker Group
sudo groupadd docker

# Add the `ubuntu` to the `docker` group to run docker commands without using `sudo`.
sudo usermod -aG docker ubuntu    # VEYA     sudo usermod -aG docker $USER

# check if ubuntu was added to docker group
grep docker /etc/group      #  docker:x:120:ubuntu

# `newgrp` command can be used activate `docker` group for `ubuntu`
newgrp docker

# Check the docker version without `sudo`.
docker version
# Check the docker info without `sudo`.
docker info
```

- GitLab ssh ile ec2'ya bağlanacak, private key `arrow-gitlab.pem` içeriğini lokalden kopyala
- Pipeline hazırlamadan önce pipeline içinde kullanacağımız `private key : arrow-gitlab.pem`in  variable olarak tanımlanması :
   - `Settings` --> `CI/CD` --> `Variables` - `Expand` --> `Add variable` ==> `Key` : `SSH_KEY `
                                                                          ==> `Value` : `***************` ***ÖNEMLİ : içeriğin sonunda 1 defa enter'a bas ve boş bir satır oluştur***
                                                                          ==> `Type` : `File`   ***ÖNEMLİ***
                                                                          ==> `Environment` : `Default`
                                                                                                        --> Click `Add variable`



- Click `.gitlab-ci.yml` -->> `Edit` -->> `Edit single file` --> copy-paste


```yaml (.gitlab-ci.yml)
variables:
  IMAGE_NAME: alparslanu6347/python-app-gitlab  
  IMAGE_TAG: python-demo-v$CI_PIPELINE_IID  # CI_PIPELINE_IID : predefined variable

stages:
  - test
  - build
  - deploy

run_test:
  stage: test
  image: python:3.8-alpine 
  script:
    - python --version
    - pip3 --version
    - pwd
    - whoami

build_image:
  stage: build
  image: docker:24.0.5 
  services:
    - docker:24.0.5-dind
  variables:
    DOCKER_TLS_CERTDIR: "/certs"
  before_script:
    - docker login -u $DOCKER_HUB_USER -p $DOCKER_HUB_PWD  
  script:  
    - docker build -t $IMAGE_NAME:$IMAGE_TAG .
    - docker push $IMAGE_NAME:$IMAGE_TAG

# variable'ı gitlab dashboard'dan eklerken < `Type` : `File` > OLACAK, AWS ec2-instance'a bağlanırken kulandığın key içeriğini kopyala-yapıştır ve sonrasında 1 Enter vur ki 1 satır boşluk oluşsun, gitlab temporary file oluşturacak bundan
deploy:
  stage: deploy
  before_script:
    - chmod 400 $SSH_KEY
  script:   # do not forget copy Public IP address of ec2-instance and change & ec2-instance needs to pull image, so needs to docker login
    - ssh -o StrictHostKeyChecking=no -i $SSH_KEY ubuntu@54.89.207.38 "
      docker login -u $DOCKER_HUB_USER -p $DOCKER_HUB_PWD && 
      docker rm -f $(docker ps -aq) || docker image prune -af &&
      docker run -d -p 8080:8080 $IMAGE_NAME:$IMAGE_TAG"
```
- Click `Commit changes`
- Pipeline aşamalarını/joblarını buradan gözlemleyebilirsin `Build` -- `Pipelines`
- uygulamayı görmek için : http://Public IP of ec2:8080  uygulamayı görmek için

# Resources

- https://gitlab.com/arrowlevent/python-demoapp-gitlab

