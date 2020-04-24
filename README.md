# sonic-buildimage-new-docker-example-http
Example to start Web server in Azure sonic-buildimage



docker-bigfoot - container for web server

```
make target/docker-bigfoot.gz



Inside SONIC target board:-
~# docker load -i /home/admin/docker-bigfoot.gz
2c995a2087c1: Loading layer [==================================================>]  105.6MB/105.6MB
5cf472718fca: Loading layer [==================================================>]  81.39MB/81.39MB
e993f69ad2a5: Loading layer [==================================================>]  100.9MB/100.9MB
3c9ea5d5c0da: Loading layer [==================================================>]  22.97MB/22.97MB
Loaded image: docker-bigfoot:latest



~# bigfoot-docker-service.sh start
Creating new bigfoot container with HWSKU db98cx8580_32cd

39b224f8bf05ecf28383d97af9dec3a5dadcad0487b9e75a5beac7098d508099
bigfoot

~# docker ps
CONTAINER ID        IMAGE                             COMMAND                  CREATED              STATUS              PORTS               NAMES
39b224f8bf05        docker-bigfoot:latest             "/usr/bin/docker_ini…"   About a minute ago   Up 48 seconds                           bigfoot

~# docker exec -it bigfoot bash
/# ps -ef
UID        PID  PPID  C STIME TTY          TIME CMD
root         1     0  0 17:37 pts/0    00:00:00 /usr/bin/python /usr/bin/supervisord
root        11     1  0 17:37 pts/0    00:00:00 python /usr/bin/supervisor-proc-exit-listener
root        15     1  0 17:37 pts/0    00:00:00 /usr/sbin/rsyslogd -n
root        44     1  0 17:37 ?        00:00:00 /usr/sbin/apache2 -k start
www-data    47    44  0 17:37 ?        00:00:00 /usr/sbin/apache2 -k start
www-data    48    44  0 17:37 ?        00:00:00 /usr/sbin/apache2 -k start
www-data    49    44  0 17:37 ?        00:00:00 /usr/sbin/apache2 -k start
root       106     0  0 17:38 pts/1    00:00:00 bash
root       111   106  0 17:38 pts/1    00:00:00 ps -ef




http://<BoardIP>/
http://<BoardIP>/cgi-bin/bigfoot-counter
http://<BoardIP>/cgi-bin/bigfoot-counter-db
```
