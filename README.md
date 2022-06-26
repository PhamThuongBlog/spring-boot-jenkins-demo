## About

This is a repository for demonstration of how Jenkins can be used for Spring Boot with Docker.

## Overview

Here is the repository overview.

1. Create two projects:
    - A Spring Boot application
    - An empty project for Jenkins
2. Push the Spring Boot application to GitHub repository. (`main` branch)
3. Run (tests) and build Docker container on Jenkins.
4. Push the built image to DockerHub. **(On your own)**
5. Pull the image in the production server and run the image. Do this whenever a new image is released. **(On your own)**

## Projects

- [Spring Boot](https://github.com/litsynp/spring-boot-minimal-demo.git)
    - Spring Boot application
    - Dockerfile
- [Jenkins](https://github.com/litsynp/spring-boot-jenkins-demo.git)
    - Dockerfile / Docker Compose

## Create Spring Boot Project

Create a Spring Boot project however you want to do.

I used [Spring Initializr](https://start.spring.io/).

My sample project [here](https://github.com/litsynp/spring-boot-minimal-demo).

## Create Jenkins Project

Create an empty project. (I used IntelliJ.)

Create `docker-compose.yml`.

```yaml
version: '3.8'
services:
  jenkins:
    image: jenkins/jenkins:jdk17-preview
    privileged: true
    user: root
    ports:
      - '8080:8080'
      - '50000:50000'
    container_name: jenkins
    volumes:
      - ./jenkins_configuration:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock

```

Create `init.sh`. You are going to need this to install Docker on Jenkins container.

```yaml
#!/bin/sh
  docker exec -it -u root jenkins sh -c \
    'curl https://get.docker.com/ > dockerinstall &&
chmod 777 dockerinstall &&
./dockerinstall &&
chmod 666 /var/run/docker.sock'
```

That’s it! Let’s set up Jenkins.

## Set Up Jenkins

### Step 1. Set Up Jenkins

Create Jenkins Docker service.

```bash
$ docker-compose up
```

When you run `docker-compose up`, you will see ***admin password*** on console. You will need this for unlocking Jenkins very soon.

And also note that `jenkins_configuration` folder is created. This is from your `docker-compose.yml` volume definition, and is for your Jenkins configurations, plugins, projects and etc.

When Docker container is created, go to [http://localhots:8080](http://localhots:8080) to see **Unlock Jenkins** page.

Enter the ***admin password***.

When you forgot to see the password, enter this.

```bash
$ docker-compose logs
```

When you enter **Customize Jenkins** Page, Click on **Install suggested plugins**. Wait for a while to install plugins.

Then you will be prompted to create admin account.

Create your admin account and click. You need to remember this information you typed.

When you’re done, click on **Save and Continue**.

On **Instance Configuration**, enter your Jenkins URL. Usually it’s *<Server IP>:8080* on default. I entered *localhost:8080* because I’m running locally.

Now you will enter the **main page** of Jenkins!

### Step 2. Install Docker

We will be using Docker to containerize our Spring Boot application. We will need to install Docker inside Jenkins container.

First, grant execution access for running the script `init.sh`. Then run `init.sh` to install Docker.

The script will download Docker from remote script from [https://get.docker.com](https://get.docker.com).

```bash
$ chmod +x ./init.sh
$ ./init.sh
# You will install Docker within Jenkins container
```

### Step 3. Create Jenkins SSH Key

You need to create Jenkins SSH key to clone from Spring Boot application repository on GitHub.

Run these commands:

```bash
# Enter shell of Jenkins container
$ docker-compose exec jenkins sh

# Go to Jenkins home and create .ssh directory
$ cd /var/jenkins_home
$ mkdir .ssh
$ cd ./.ssh

# Create SSH key
$ ssh-keygen -t rsa -f /var/jenkins_home/.ssh/jenkins_ci
# You will be prompted to enter passphrase. You don't need to.

# Check private key
cat jenkins_ci
```

Copy the result of `cat jenkins_ci`. This is your ***private key***, which must not be exposed to public. We will register this to your Spring Boot application repository on GitHub soon.

### Step 3.1. Register Private Key to Jenkins

Go to **Manage Jenkins**.

![Manage Jenkins](https://user-images.githubusercontent.com/42485462/175804682-b670ec87-5eef-48ef-b4a3-8bba8225ba62.png)

Goto **Manage Credentials**.

![Manage Credentials](https://user-images.githubusercontent.com/42485462/175804685-8d438ba5-5548-4e89-9197-a158a5150aa7.png)

Hover over **(global)** and click on **Add credentials**.

![Add Credentials - Global](https://user-images.githubusercontent.com/42485462/175804689-6e1466b8-332b-4f04-b918-a7e97ebf08dc.png)

Select **SSH Username and private key** from **Kind**.

![SSH Username and PK](https://user-images.githubusercontent.com/42485462/175804692-98f21245-762b-4588-9de6-56508d923b29.png)

![Enter SSH](https://user-images.githubusercontent.com/42485462/175804696-58f245af-762d-4be4-b99a-dd95dd813775.png)

Enter username, and your SSH ***private key*** from previous step.

Then create your credential!

### Step 3.2. Register Public Key to Jenkins

We start from the shell in Jenkins container from Step 3.

Check the SSH public key.

```bash
$ cat jenkins_ci.pub
ssh-rsa xxxxxxxxxxxxxxxxx root@xxxxxxx
```

Now let’s go to GitHub to register public key.

Go to GitHub repository of your Spring Boot application.

Click on **Settings**.

![SB Settings](https://user-images.githubusercontent.com/42485462/175804679-21769381-6e9a-4b74-8a9c-5ff68734e544.png)

Then **Deploy Keys**.

![Deploy Keys](https://user-images.githubusercontent.com/42485462/175804792-7422f096-e1e6-49ee-bc3c-647c3a650cc2.png)

Click on **Add deploy key**.

![Add deploy key](https://user-images.githubusercontent.com/42485462/175804794-0f409a74-33c8-46b3-b804-768c2fa24196.png)

Register as deploy key. Paste your public key.

![Add new](https://user-images.githubusercontent.com/42485462/175804796-3a65e5a1-ed60-4f23-a85c-7e9b7dae6139.png)

Click on **Add key** and enter GitHub password to finish registering the key.

![Deploy keys result](https://user-images.githubusercontent.com/42485462/175804799-8e608ac0-60c9-4990-96ef-940b4962f61e.png)

Now, let’s create a project on Jenkins. We’re almost done.

### Step 3.3. Add Webhook

If your Jenkins instance is running on public cloud like AWS, you can make a webhook so that whenever a push event to the repository is triggered, Jenkins can know about it.

Add your Jenkins URL as the **Payload URL**.

![Add Webhook](https://user-images.githubusercontent.com/42485462/175804883-ea3241aa-0740-4661-a400-331320989f57.png)

If you’re just running on localhost, there is no need.

### Step 4. Create Project

Go to Jenkins and click on **New Item**.

![New Item](https://user-images.githubusercontent.com/42485462/175804885-90a482ce-9979-4b41-bc5f-c1f10bb173d3.png)

Enter item name and click on **Freestyle project**. Click on **OK**.

![Freestyle Project](https://user-images.githubusercontent.com/42485462/175804886-a9b5146f-a2bd-42f3-b12d-c61ca9682bb9.png)

Click on **Source Code Management**.

![SCM](https://user-images.githubusercontent.com/42485462/175804888-8399a4a2-22c8-4c07-a31c-61102d8f57bb.png)

Go to GitHub and copy the Git repository URL.

![Git repo URL](https://user-images.githubusercontent.com/42485462/175804890-bb28e24c-205b-449f-9535-28d688f5d8d7.png)

Back to Jenkins, go ahead and add repository URL to clone from.

![SCM Git URL](https://user-images.githubusercontent.com/42485462/175804897-5724e599-ed5e-41c0-b438-4ed2bd5dc5e7.png)

For **Credentials**, select the credentials we added previously.

Write down the branches to build. We are only using `main` branch, so `main` it is.

![SCM Branch](https://user-images.githubusercontent.com/42485462/175804901-33eaca25-6362-4a73-b4e5-f2b6a5d278eb.png)

For **Build**, we will add multiple commands so that it looks like this.

![Build 1](https://user-images.githubusercontent.com/42485462/175804905-e24d883b-5091-465b-8680-67ad69111e82.png)

**…**

**…**

![Build 2](https://user-images.githubusercontent.com/42485462/175804907-3528aec6-823d-457f-b55d-13b11a9a8d41.png)

The commands you will be adding are:

```bash
# Build the Spring Boot application
./gradlew clean build

# Build a new Spring Boot Docker image
docker build -t jenkins/testapp .

# Remove previously running Docker container
docker ps -q --filter "name=jenkins-testapp" | grep -q . && docker stop jenkins-testapp && docker rm jenkins-testapp || true

# Run the new image
docker run -p 8081:8080 -d --name=jenkins-testapp jenkins/testapp

# Remove dangling image
docker rmi -f $(docker images -f "dangling=true" -q) || true
```

If you want to **test** and build if successful, add this command on top.

```bash
./gradlew test
```

Now click on **Save**.

### Step 5. Build the Project

If you’ve registered a webhook to GitHub, make a change to your Spring Boot application, and commit and push to GitHub remote repository.

If not, just click on **Build Now**.

![Build Now](https://user-images.githubusercontent.com/42485462/175804909-068c881f-6cd1-4993-a483-b69cf8bff609.png)

### Console Output — Build Success

```bash
Started by user SJ
Running as SYSTEM
Building in workspace /var/jenkins_home/workspace/Jenkins Demo Project
The recommended git tool is: NONE
using credential XXXXXXXXXXXXXXXXXXXX
 > git rev-parse --resolve-git-dir /var/jenkins_home/workspace/Jenkins Demo Project/.git # timeout=10
Fetching changes from the remote Git repository
 > git config remote.origin.url https://github.com/litsynp/spring-boot-minimal-demo.git # timeout=10
Fetching upstream changes from https://github.com/litsynp/spring-boot-minimal-demo.git
 > git --version # timeout=10
 > git --version # 'git version 2.30.2'
using GIT_SSH to set credentials 
 > git fetch --tags --force --progress -- https://github.com/litsynp/spring-boot-minimal-demo.git +refs/heads/*:refs/remotes/origin/* # timeout=10
 > git rev-parse refs/remotes/origin/main^{commit} # timeout=10
Checking out Revision e6a2e09a293019dbd5b1a7543138701c3b19ddca (refs/remotes/origin/main)
 > git config core.sparsecheckout # timeout=10
 > git checkout -f e6a2e09a293019dbd5b1a7543138701c3b19ddca # timeout=10
Commit message: "build: init project"
 > git rev-list --no-walk e6a2e09a293019dbd5b1a7543138701c3b19ddca # timeout=10
[Jenkins Demo Project] $ /bin/sh -xe /tmp/jenkins6158032395134023556.sh
+ ./gradlew clean build
Starting a Gradle Daemon (subsequent builds will be faster)
> Task :clean
> Task :compileJava
> Task :processResources
> Task :classes
> Task :bootJarMainClassName
> Task :bootJar
> Task :jar
> Task :assemble
> Task :compileTestJava
> Task :processTestResources NO-SOURCE
> Task :testClasses
> Task :test
> Task :check
> Task :build

BUILD SUCCESSFUL in 34s
8 actionable tasks: 8 executed
[Jenkins Demo Project] $ /bin/sh -xe /tmp/jenkins16304256926735885325.sh
+ docker build -t jenkins/testapp .
#1 [internal] load build definition from Dockerfile
#1 sha256:8110e9c4b0763581e5a636c4f5e5d049910c63817de4239fac473e17d953cd39
#1 transferring dockerfile: 32B 0.0s done
#1 DONE 0.0s

#2 [internal] load .dockerignore
#2 sha256:cb73a78fab1322ed64ffaca9aeae60533d7fa28609e570963a377f67f67e87dc
#2 transferring context: 2B 0.0s done
#2 DONE 0.0s

#3 [internal] load metadata for docker.io/library/eclipse-temurin:17.0.3_7-jre
#3 sha256:8628f37fbe73740572e63143aea697926a67db53e954fdf9581285678dd72e46
#3 DONE 1.9s

#4 [1/2] FROM docker.io/library/eclipse-temurin:17.0.3_7-jre@sha256:9e1e08a26000ca8ef3a0d48f2b63c3a2e931d23d69e1a2aede3f5d74dd3aa44d
#4 sha256:a44431dc4ffead9912d1523a49dfe31462a93559c0f4f1968e12947ab6336763
#4 DONE 0.0s

#5 [internal] load build context
#5 sha256:f09122f0ed51b2f7b7b0ce5b41ea02f8bfbfffb4ac49ea0171aad58bf9e27d4f
#5 transferring context: 17.63MB 0.8s done
#5 DONE 0.9s

#4 [1/2] FROM docker.io/library/eclipse-temurin:17.0.3_7-jre@sha256:9e1e08a26000ca8ef3a0d48f2b63c3a2e931d23d69e1a2aede3f5d74dd3aa44d
#4 sha256:a44431dc4ffead9912d1523a49dfe31462a93559c0f4f1968e12947ab6336763
#4 CACHED

#6 [2/2] COPY build/libs/*.jar app.jar
#6 sha256:2df9c8c81483d2eba64bcd292bb80a3d22de844a5769bdb3f10cf76cbae2891d
#6 DONE 0.1s

#7 exporting to image
#7 sha256:e8c613e07b0b7ff33893b694f7759a10d42e180f2b4dc349fb57dc6b71dcab00
#7 exporting layers 0.0s done
#7 writing image sha256:36dd75a5274c89c16d1ae78679fa7340127c59dd8fed7f2510e128abecd7d86a done
#7 naming to docker.io/jenkins/testapp done
#7 DONE 0.0s
[Jenkins Demo Project] $ /bin/sh -xe /tmp/jenkins12714354591949316247.sh
+ docker ps -q --filter name=jenkins-testapp
+ grep -q .
+ docker stop jenkins-testapp
jenkins-testapp
+ docker rm jenkins-testapp
jenkins-testapp
[Jenkins Demo Project] $ /bin/sh -xe /tmp/jenkins9423869506988446892.sh
+ docker run -p 8081:8080 -d --name=jenkins-testapp jenkins/testapp
e1979b54de991e49f174ccc7f73c4e5e4cf5ce6cc1529369a58e28a21d28a436
[Jenkins Demo Project] $ /bin/sh -xe /tmp/jenkins10550198681401786417.sh
+ docker images -f dangling=true -q
+ docker rmi -f cc17373da9ec
Deleted: sha256:cc17373da9ecdc98633d5b322bd9d0e20420fb165fbf99cb4532fe825b6e1d1f
Finished: SUCCESS
```

Now go to [localhost:8081](http://localhost:8081) or wherever you’ve made your Spring Application to deploy to.

And you're good to go!

If you want to add more plugins like Slack notification for build success, you can look for it on your own.

## REF

[Jenkins + Spring Boot (Korean)](https://velog.io/@hind_sight/Docker-Jenkins-%EB%8F%84%EC%BB%A4%EC%99%80-%EC%A0%A0%ED%82%A8%EC%8A%A4%EB%A5%BC-%ED%99%9C%EC%9A%A9%ED%95%9C-Spring-Boot-CICD)

[Jenkins + Python Django + docker-compose for Jenkins (Korean)](https://www.dongyeon1201.kr/9026133b-31be-4b58-bcc7-49abbe893044#8325a9d5-df30-44d8-b422-89d8d0307e88)

[How to Install and Run Jenkins With Docker Compose](https://www.cloudbees.com/blog/how-to-install-and-run-jenkins-with-docker-compose)
