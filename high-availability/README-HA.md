# High Availability using HAProxy and KeepAlived - on Docker-Compose
HAProxy is perhaps the fastest reverse proxy at the moment. (sorry Nginx fans). It has the following qualities:
* Very fast - written in C
* Very small memory footprint at runtime
* Very fast processing of network packets/traffic - almost wire-speed
* Very simple, clean and organized configuration file
* It is only a reverse proxy, nothing else

Nginx on the other hand, *may be fast*, but I do not like it because:
* It's configuration file(s) suffer the same problem as Apache - i.e. complexity
* Above is bad enough, so I don't have to list more points

To build a proof of concept setup using one reverse proxy instance of HAProxy and one of more instances of backend servers, is very easy on docker-compose. i.e. You really don't need three VMs to build a POC.

However, if you want to build a POC of HAProxy running in HA mode itself, serving a farm of servers as backend, then the most logical choice is to use VMs. 

I thought, I can try setting up a docker-compose setup, in which HAProxy will also run in HA mode, using Keepalived, and floating IP address, etc. Though the immediate challenge was we need to configure the virtual IP in keepalived, and how would we know what network range we will get when we start our compose stack? I solved that by manually creating a docker network in bridge mode, `proxy-network`, with a subnet address provided by myself, `192.168.200.0/24`. Then, in my docker-compose file, I made sure that all containers connect to this "external" network. 
The other problem with this (docker-compose) setup is that you cannot bind mount port 80 or 443 from two containers on the host. i.e. When there are two instances of HAProxy running , with a floating IP, you never know which instance will have the floating IP at any given time, and which instance to bind mount to the external host. Well, this is needed only if you want to test the reverse proxy through your host computer, normally your work computer. Since it is a problem, the best is NOT to test this setup through your work computer OS. Instead, add an additional container in the same compose stack, which will be used as a "client". That way, I don't need to bind mount the haproxy container ports on the host at all. I don't even need to list/mention any ports in the docker-compose file, as all containers inside one docker network can access all (availabl) ports on all other containers of the same network. 

Some reference material is here:
* https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/load_balancer_administration/keepalived_install_example1
* https://youtu.be/o2zGUnL3tP8

```
[kamran@kworkhorse https]$ docker network create proxy-network  --subnet=192.168.200.0/24
```

```
[kamran@kworkhorse https]$ docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
b4e4a044bb14        bridge              bridge              local
f95d42d96150        host                host                local
3b957f269738        https_default       bridge              local
6f87ba2c3e3a        none                null                local
4bdf42b2e62a        proxy-network       bridge              local
[kamran@kworkhorse https]$ 
```

```
# keepalived --use-file /etc/keepalived/keepalived.conf  --log-console --dont-fork 
Tue Mar 17 20:44:41 2020: Starting Keepalived v2.0.19 (11/24,2019), git commit v20191114-652-g038556d644
Tue Mar 17 20:44:41 2020: Running on Linux 5.5.7-200.fc31.x86_64 #1 SMP Fri Feb 28 17:18:37 UTC 2020 (built for Linux 4.19.36)
Tue Mar 17 20:44:41 2020: Command line: 'keepalived' '--use-file' '/etc/keepalived/keepalived.conf' '--log-console'
Tue Mar 17 20:44:41 2020:               '--dont-fork'
Tue Mar 17 20:44:41 2020: Opening file '/etc/keepalived/keepalived.conf'.
Tue Mar 17 20:44:41 2020: Failed to bind to process monitoring socket - errno 1 - Operation not permitted
Tue Mar 17 20:44:41 2020: Starting VRRP child process, pid=273
Tue Mar 17 20:44:41 2020: Registering Kernel netlink reflector
Tue Mar 17 20:44:41 2020: Registering Kernel netlink command channel
Tue Mar 17 20:44:41 2020: Opening file '/etc/keepalived/keepalived.conf'.
Tue Mar 17 20:44:41 2020: WARNING - default user 'keepalived_script' for script execution does not exist - please create.
Tue Mar 17 20:44:41 2020: SECURITY VIOLATION - scripts are being executed but script_security not enabled.
Tue Mar 17 20:44:41 2020: Registering gratuitous ARP shared channel
Tue Mar 17 20:44:41 2020: Netlink: error: Operation not permitted(1), type=RTM_DELADDR(21), seq=1584477885, pid=0
Tue Mar 17 20:44:41 2020: VRRP_Script(check_haproxy) succeeded
Tue Mar 17 20:44:41 2020: (VI_1) Entering BACKUP STATE
Tue Mar 17 20:44:45 2020: (VI_1) Entering MASTER STATE
Tue Mar 17 20:44:45 2020: Netlink: error: Operation not permitted(1), type=RTM_NEWADDR(20), seq=1584477886, pid=0
^CTue Mar 17 20:44:56 2020: Stopping
Tue Mar 17 20:44:56 2020: (VI_1) sent 0 priority
Tue Mar 17 20:44:57 2020: Stopped
Tue Mar 17 20:44:57 2020: Stopped Keepalived v2.0.19 (11/24,2019), git commit v20191114-652-g038556d644
/ # pkill keepalived
```

```
/ # [kamran@kworkhorse kubernetes]$ docker exec -it high-availability_web1_1 /bin/sh
/ # touch /usr/share/nginx/html/backend.member
```

/ # [kamran@kworkhorse kubernetes]$ docker exec -it high-availability_web2_1 /bin/sh
/ # touch /usr/share/nginx/html/backend.member
/ #
``` 


```
[kamran@kworkhorse tmp]$ docker exec -it high-availability_haproxy-master_1 /bin/sh
/ # keepalived --use-file /etc/keepalived/keepalived.conf  --log-console --dont-fork
Tue Mar 17 20:50:53 2020: Starting Keepalived v2.0.19 (11/24,2019), git commit v20191114-652-g038556d644
Tue Mar 17 20:50:53 2020: Running on Linux 5.5.7-200.fc31.x86_64 #1 SMP Fri Feb 28 17:18:37 UTC 2020 (built for Linux 4.19.36)
Tue Mar 17 20:50:53 2020: Command line: 'keepalived' '--use-file' '/etc/keepalived/keepalived.conf' '--log-console'
Tue Mar 17 20:50:53 2020:               '--dont-fork'
Tue Mar 17 20:50:53 2020: Opening file '/etc/keepalived/keepalived.conf'.
Tue Mar 17 20:50:53 2020: Starting VRRP child process, pid=17
Tue Mar 17 20:50:53 2020: Registering Kernel netlink reflector
Tue Mar 17 20:50:53 2020: Registering Kernel netlink command channel
Tue Mar 17 20:50:53 2020: Opening file '/etc/keepalived/keepalived.conf'.
Tue Mar 17 20:50:53 2020: WARNING - default user 'keepalived_script' for script execution does not exist - please create.
Tue Mar 17 20:50:53 2020: SECURITY VIOLATION - scripts are being executed but script_security not enabled.
Tue Mar 17 20:50:53 2020: Registering gratuitous ARP shared channel
Tue Mar 17 20:50:53 2020: VRRP_Script(check_haproxy) succeeded
Tue Mar 17 20:50:53 2020: (VI_1) Entering BACKUP STATE
Tue Mar 17 20:50:57 2020: (VI_1) Entering MASTER STATE
```



```
/ # [kamran@kworkhorse tmp]$ docker exec -it high-availability_haproxy-backup_1 /bin/sh
/ # keepalived --use-file /etc/keepalived/keepalived.conf  --log-console --dont-fork
Tue Mar 17 20:50:58 2020: Starting Keepalived v2.0.19 (11/24,2019), git commit v20191114-652-g038556d644
Tue Mar 17 20:50:58 2020: Running on Linux 5.5.7-200.fc31.x86_64 #1 SMP Fri Feb 28 17:18:37 UTC 2020 (built for Linux 4.19.36)
Tue Mar 17 20:50:58 2020: Command line: 'keepalived' '--use-file' '/etc/keepalived/keepalived.conf' '--log-console'
Tue Mar 17 20:50:58 2020:               '--dont-fork'
Tue Mar 17 20:50:58 2020: Opening file '/etc/keepalived/keepalived.conf'.
Tue Mar 17 20:50:58 2020: Starting VRRP child process, pid=16
Tue Mar 17 20:50:58 2020: Registering Kernel netlink reflector
Tue Mar 17 20:50:58 2020: Registering Kernel netlink command channel
Tue Mar 17 20:50:58 2020: Opening file '/etc/keepalived/keepalived.conf'.
Tue Mar 17 20:50:58 2020: WARNING - default user 'keepalived_script' for script execution does not exist - please create.
Tue Mar 17 20:50:58 2020: SECURITY VIOLATION - scripts are being executed but script_security not enabled.
Tue Mar 17 20:50:58 2020: Registering gratuitous ARP shared channel
Tue Mar 17 20:50:58 2020: VRRP_Script(check_haproxy) succeeded
Tue Mar 17 20:50:58 2020: (VI_1) Entering BACKUP STATE
```


------------


Test from the client container:
```
[kamran@kworkhorse high-availability]$ docker exec -it high-availability_client_1 /bin/sh
/ # ifconfig
eth0      Link encap:Ethernet  HWaddr 02:42:C0:A8:C8:06  
          inet addr:192.168.200.6  Bcast:192.168.200.255  Mask:255.255.255.0
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:31 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0 
          RX bytes:3984 (3.8 KiB)  TX bytes:0 (0.0 B)

lo        Link encap:Local Loopback  
          inet addr:127.0.0.1  Mask:255.0.0.0
          UP LOOPBACK RUNNING  MTU:65536  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000 
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
```

```
/ # ping -c 1  192.168.200.100
PING 192.168.200.100 (192.168.200.100) 56(84) bytes of data.
64 bytes from 192.168.200.100: icmp_seq=1 ttl=64 time=0.171 ms

--- 192.168.200.100 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.171/0.171/0.171/0.000 ms
```

```
/ # curl -L -k 192.168.200.100
<title>Web 1</title>
<h1>Web 1</h1>


/ # curl -L -k 192.168.200.100
<title>Web 2</title>
<h1>Web 2</h1>


/ # curl -L -k 192.168.200.100
<title>Web 1</title>
<h1>Web 1</h1>


/ # curl -L -k 192.168.200.100
<title>Web 2</title>
<h1>Web 2</h1>
/ # 
```



