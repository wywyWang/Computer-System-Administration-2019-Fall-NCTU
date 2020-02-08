# SA HW3

## Pure-ftpd
- [參考網址一:SA筆記](https://www.hwchiu.com/pure-ftpd.html?fbclid=IwAR1DpKi7C4yViu-jNqqXWIaVw6wf_pwb4Bgoq1i5wS3vXTfbH-QKpPxJSqw)
- [參考網址二](https://forums.freebsd.org/threads/howto-setup-a-pure-ftpd-server-with-virtual-users.591/?fbclid=IwAR34pjEfo-b4c7PO6qXfudSy2O9ocmEhrMtY21vzuoGK01bF8SQYlgqYcBw)
- [參考網址三](http://mail.lsps.tp.edu.tw/~gsyan/freebsd2001/ftp-pureftpd.html?fbclid=IwAR10TMDvC-GPOuuSOTl_zmVahm8_n5zZZfHzMtedK84t95oa6OnrHkj3CTE)
- [參考網址四](https://linoxide.com/linux-how-to/install-pure-ftpd-tls-freebsd-10-2/?fbclid=IwAR3vTu8OlAoH_j3zcaj55XF5Awh1P_M1DlQRirCK9qwlx9-VgipmaouPd7Y)

### Step
- copy sample to pure-ftpd.conf
- vim /usr/local/etc/pure-ftpd.conf
    - **For Anonymous**
        - NoAnonymous no
        - AntiWarez no
        - AnonymousCanCreateDirs no
        - AnonymousCan`tUpload no
    - **For virtual user**
        - PureDB /usr/local/etc/pureftpd.pdb
- COMMAND
    - **Sysadm**
        - adduser
        - pure-pw useradd sysadm -u sysadm -g virtualgroup -d /home/ftp -m
    - **Anonymous**
        - pw groupadd ftpuser
        - pw useradd ftp -g ftpuser -d /home/ftp
    - **ftp-vip1**
        - pw groupadd virtualgroup
        - pw useradd ftpuser -g virtualgroup -c “FTP virtual user” -d /home/ftp -s /sbin/nologin
        - pure-pw useradd ftp-vip1 -u ftpuser -g virtualgroup -d /home/ftp -m
    - **ftp-vip2**
        - pw useradd ftpuser2 -g virtualgroup -c "FTP virtual user 2" -d /home/ftp -s /sbin/nologin
        - pure-pw useradd ftp-vip2 -u ftpuser2 -g virtualgroup -d /home/ftp -m

- Set directory permission
    - **public**
        - chown sysadm:virtualgroup /home/ftp/public
        - chmod 777 /home/ftp/public
    - **upload**
        - chown sysadm:virtualgroup /home/ftp/upload
        - chmod 1777 /home/ftp/upload
    - **hidden**
        - chown sysadm:virtualgroup /home/ftp/hidden
        - chmod 771 /home/ftp/hidden

- **測試TLS**
    - [可參考](https://leoyeh.me/2017/09/11/%E8%A7%A3%E6%B1%BA%E5%95%8F%E9%A1%8C-SSL-TLS-6/)
    -  sudo openssl s_client -connect 10.113.0.75:21 -starttls ftp -CAfile /etc/ssl/private/pure-ftpd.pem

---

## ZFS

:::info
可以用df-h或是zpool status查看
[**可參考1**](https://blog.xuite.net/kb8.gyes/free/30794110-ZFS+%E7%9C%9F%E6%98%AF%E4%B8%80%E5%80%8B%E4%B8%8A%E5%B8%9D%E8%B3%9C%E7%B5%A6IT%E4%BA%BA%E5%93%A1%E7%9A%84%E5%A5%BD%E7%A6%AE%E7%89%A9%21%21%21)
[**中文文件**](https://www.freebsd.org/doc/zh_TW/books/handbook/zfs-zfs.html)
[ln用法](https://www.opencli.com/linux/ln-create-link-command)
:::

- vim /etc/rc.conf
    - zfs_enable="YES"
- 先在VM新建兩個硬碟叫ada1，ada2
- zpool create mypool mirror /dev/ada1 /dev/ada2
- zfs set compression=lz4 mypool
- zfs set atime=off mypool
- ~~Create ZFS datasets~~
    - ~~zfs set mountpoint=/home/ftp mypool~~
    - ~~zfs create mypool/public~~
    - ~~zfs create mypool/hidden~~
    - ~~zfs create mypool/upload~~

- Create ZFS datasets(new version)
    - zfs set mountpoint=/ftp mypool
    - zfs create mypool/public
    - zfs create mypool/hidden
    - zfs create mypool/upload
    - ln -s /ftp/  /home/ftp

- 測試
    - zfs snapshot mypool@test
    - zfs rollback mypool@test

- Zbackup
    - vim /usr/local/bin/zbackup
    - **BUG**
        - none
    - gzip
        - Compress:
            - zfs send mypool@2019-11-24-12:45:34 | gzip > output.gz
            - gzip testfile
        - Decompress:
            - gzip -d testfile.gz
    - openssl
        - openssl enc -aes-256-cbc -iter 1000 -in test_compress.gz -out test.gz.enc
        - openssl enc -aes-256-cbc -d -iter 1000 -in test.gz.enc -out test.gz

---

## Pure-ftpd uploadscript with RC

:::info
[參考一](https://kknews.cc/zh-tw/code/l3nq9ez.html)
[參考二](https://www.freebsd.org/doc/zh_TW/books/handbook/configtuning-rcd.html)
[參考三](https://www.freebsd.org/doc/en_US.ISO8859-1/articles/rc-scripting/rcng-dummy.html)
[參考四](https://www.freebsd.org/doc/en_US.ISO8859-1/articles/rc-scripting/rcng-daemon-adv.html)
:::

- vim /usr/local/etc/pure-ftpd.conf
    - CallUploadScript yes
- /usr/local/bin/uploadscript.sh
    - [參數可參考](https://linux.die.net/man/8/pure-uploadscript)
- vim /etc/rc.d/ftp_watchd
    - **記得給他執行權限**

