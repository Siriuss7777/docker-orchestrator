# docker-orchestrator

Simple bash orcherstrator for docker-compose containers.

## Setup

~~~
ln -s /opt/orchestrator/docker-orchestrator.sh /bin/orch
ln -s /opt/orchestrator/autocomp-docker-orchestrator /etc/bash_completion.d/docker-orchestrator
source ~/.bashrc
~~~

## Default infrasctructure
```
├── /opt/
│   ├── docker/
│   │   ├── available/ 
│   │   │   ├── service1/docker-compose.yml
│   │   │   ├── service2/docker-compose.yml
│   │   │   ├── [...]
│   │   ├── enabled/
│   │   │   ├── [automatically generated and managed]
```

## Future improvements
* Do not link the whole folder to enable it (rather create/delete a file to manage enabled containers...)
* ?

Made with the help of ChatGPT.
