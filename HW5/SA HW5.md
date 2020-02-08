# SA HW5

## NIS Client

- [隨筆記參考](https://vannilabetter.blogspot.com/2017/12/freebsd-nis.html)
- [NIS參考](https://samlin35.blogspot.com/2014/12/freebsd-nis-client.html)
- [NIS參考2](http://www.weithenn.org/2009/07/nis.html#Heading6)

- sudo vim /etc/rc.conf
```
nisdomainname="savpn.nctu.me"
nis_client_enable="YES"
nis_client_flags="-s -m -S savpn.nctu.me,savpn"
rpcbind_enable="yes"
```
- sudo vim /etc/hosts
```
140.113.17.155 savpn
```
- sudo vipw
```
+:::::::::
```
- sudo vim /etc/group
```
+:*::
```
- sudo vim /etc/host.conf
    - 在hosts前面加上nis

---

## NFS Client

- [雄的筆記](http://mail.lsps.tp.edu.tw/~gsyan/freebsd2001/nfs.html)

- vim /etc/rc.conf
```
nfs_client_enable="YES"
nfsuserd_enable="yes"
nfscbd_enable="YES"
```
- mount nfs server
```
sudo mount -t nfs -o nfsv4 10.113.0.254:/net/home /net/home
sudo mount -t nfs -o nfsv4 10.113.0.254:/net/data /net/data
```
- automount
    - vim /etc/rc.conf
    ```
    autofs_enable="YES"
    ```
    - vim /etc/auto_master
    ```
    /-        /etc/auto_map       -intr
    ```
    - vim /etc/auto_map
    ```
    /net/home -rw,soft,nosuid 10.113.0.254:/net/home
    /net/data -ro,soft,nosuid 10.113.0.254:/net/data
    ```
    
:::    success
Test
showmount -a 10.113.0.254
:::

---

## NFS Server

- [隨筆記](https://vannilabetter.blogspot.com/2017/12/freebsd-nfsv4.html)
- [鳥哥](http://linux.vbird.org/linux_server/0330nfs.php#nfsserver_exports)

- vim /etc/rc.conf
```
# nfs
nfs_server_enable="yes"
nfs_server_flags="-u -t -n 4"
nfsv4_server_enable="yes"
nfsuserd_enable="yes"
mountd_enable="yes"
```
- vim /etc/exports
```
V4: /net -sec=sys
/net/alpha /net/share /net/admin -maproot=nobody

```

:::    success
Test 
```
showmount -e
```
:::

---

## firewall
- enable pf
    - vim /etc/rc.conf
    ```
    pf_enable = "YES"
    pflog_enable="YES"
    pf_rules = "/etc/pf.conf"
    ```
- rules
    - Deny all connections from BadHost
    ```
    table <BadHost> persist file "/etc/badhost"
    block quick from <BadHost>
    table <BadGuy> persist file "/etc/badguy"
    block quick from <BadGuy>
    ```
    - Accept packets from 10.113.0.0/16 to access HTTP/HTTPS
    ```
    pass quick proto {tcp,udp} from {10.113.0.0/16} port {http,https}
    ```
    - All IP can’t send ICMP echo request packets to server
    ```
    先block所有，再allow(pf以最後一條符合的為rule)
    block inet proto icmp all icmp-type echoreq
    pass inet proto icmp from {10.113.0.254} icmp-type echoreq keep state
    ```
    - Drop packets from BadGuy to access FTP and SSH, and response TCP RST/ICMP unreachable
    ```
    block quick proto {tcp,udp} from $BadGuy to port {ftp,ssh}
    set block-policy return

:::    success
Test 
```
pfctl -vnf /etc/pf.conf
```
:::

---

## blacklist

- If someone attempts to login via SSH but failed for 5 times in 1 hour, then their IP will be banned from SSH for 1 day automatically

    - vim /etc/rc.conf
    ```
    blacklistd_enable="YES"
    ```

    - vim /etc/pf.conf
    ```
    anchor “blacklistd/*” in on 網卡名稱
    ```
    - vim /etc/blacklistd.conf
    ```
    ssh stream * * * 5 24h
    註解* * * * * 3 60
    ```

    - vim /etc/ssh/sshd_config
    ```
    UseBlacklist yes
    ```

    :::    success
    Test 
    ```
    sudo pfctl -a blacklistd/22 -t port22 -T show
    blacklistctl dump -br
    ```
    :::

- Write a shell script ‘iamagoodguy’ to unban an IP
    - vim /bin/iamagoodguy
    ```
    pfctl -a blacklistd/22 -t port22 -T delete 213.0.123.128/25
    ```

---

## BONUS

- Log
    - https://www.openbsd.org/faq/pf/anchors.html

- Personal webpage for NIS user
    - vim httpd-ssl.conf
    ```
    RewriteRule /people/~(.*)/$ /~$1/ [PT]
    ```
    - vim httpd-userdir.conf
    ```
    UserDir /net/home/*/public_html
    <Directory "/net/home/*/public_html">
        跟上次作業一樣
    </Directory
    ```