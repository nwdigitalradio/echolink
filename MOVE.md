## EchoLink Machine Move Notes

### Requirements
* RPi unit
* 5V Raspberry Pi wall wart
* Ethernet connection (NOT WiFi)

#### Find IP address of EchoLink RPi
* The EchoLink RPi comes configured with DHCP
* Find the IP address assigned either by looking in your Routers DHCP assignment table or:
  * Use the following command
  * nmap -p 57329 --open -sV <local_net_first_3_octets>.* -Pn
* For example

```
nmap -p 57329 --open -sV 10.0.42.* -Pn
```
* Output looks like this:
```
Starting Nmap 7.60 ( https://nmap.org ) at 2020-03-26 13:18 PDT
Nmap scan report for 10.0.42.110
```
* So the dynamic IP address is **10.0.42.110**

### Router Port Forward Configuration Notes
* Require IP address of RPi unit

#### EchoLink Port Configuration

```
                                Port    Port                                           Private
Name             Type           start   end   Protocol NAT Interface    Private IP      Port

Echolink1	Port-Remap	5198	5198	UDP	eth0.v1530	<RPi_IP_addr>	5198
Echolink2	Port-Remap	5199	5199	UDP	eth0.v1530	<RPi_IP_addr>	5199
EchoLink3	Port-Remap	5200	5200	TCP	eth0.v1530	<RPi_IP_addr>	5200
```

### Remote SSH Configuration

* Require IP address of RPi unit
* ssh port changed from default in file: /etc/ssh/sshd_config
  * Port 57329

```
                                Port    Port                                           Private
Name     Type           start   end     Protocol       NAT Interface    Private IP      Port

ssh    Port-Remap	57329	57329	TCP or UDP	eth0.v1530     <RPi_IP_addr>	573329
```
### Quick Check
* Things to check to see if RPi running EchoLink is working
  * Green led on RPi is set to blink heartbeat
  * From another computer check svxlink log file
    * ssh -p <ssh_port> pi@<RPi_IP_addr>
    * tail -f /var/log/svxlink.log
  * Using EchoLink remote device connect to N7JN-R
    * This can sometimes take a minute for the EchoLink server to find a new svxlink server (RPi)

### Misc notes
* Last things configured before delivery

#### Log file
* Added auto log rotate
  * Created these two files:
    * /etc/logrotate.d/svxlink
    * /etc/rsyslog.d/01-svxlink.conf
* Current log file is /var/log/svxlink.log

#### Fixed ip
* Added a script to facilitate changing a DHCP IP address to a static IP address
  * script ~/bin/fixed_ip.sh

