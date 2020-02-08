# SA HW4

## HTTP Server

- [2017SA詳細說明](https://vannilabetter.blogspot.com/2017/12/freebsd-apachephp.html)
- [參考二](https://www.freebsd.org/doc/zh_TW/books/handbook/network-apache.html)
- [參考三](http://mail.lsps.tp.edu.tw/~gsyan/freebsd2001/apache.html)
- [FAMP安裝教學](https://kifarunix.com/install-apache-mysql-php-famp-stack-on-freebsd-12/)
- [curl](https://blog.techbridge.cc/2019/02/01/linux-curl-command-tutorial/?fbclid=IwAR0AFo7vjIfp_5jcs0huzv1BfSrq6hGXctteOQvPJ1a0Ydf8diydIgianNw)

- 安裝apache24
    - Virtualbox要改網路設定變成橋接卡
    - /usr/local/etc/apache24/httpd.conf
        - AllowOverride All
        - htpasswd -c sahw4/.htpasswd admin
    - /usr/local/etc/apache24/extra/httpd-vhosts.conf
    - /usr/local/www/sahw4/
- 在192.168.0.1裡面設定port forwarding(**DEMO要SSH連回來測**)
    - 包含80跟443 port
- Access control
    - 在/usr/local/etc/apache24/httpd.conf加東西 [參考](https://www.twbsd.org/cht/book/ch13.htm?fbclid=IwAR0bHQIe5j2eHWT3FmsY18sPSN2GpahKBqCXBcb16n-qtXIBfWvSK7K2l_Q)
    - 在/usr/local/etc/apache24/extra/httpd-ssl.conf也要加<Location></Location>的東西，因為是在443port
    - **記得把allow IP改成題目要的，目前是錯的只是為了可以連**
- Hide tokens
    - 在httpd.conf中新增
        - ServerTokens Prod
        - ServerSignature Off
- HTTPS
    - Enable https
        - 建立/usr/local/etc/apache24/ssl/
        - 放ca_bundle.crt, certificate.crt, private.key進去
    - Redirect http to https
        - 編輯/usr/local/etc/apache24/extra/httpd-vhosts.conf
            - Redirect / https://nctu-sahw4.nctu.me/
            - Redirect /public https://nctu-sahw4.nctu.me/public/
            - Redirect /private https://nctu-sahw4.nctu.me/private/
    - Enable HSTS
        - 編輯/usr/local/etc/apache24/extra/httpd-vhosts.conf與/usr/local/etc/apache24/extra/httpd-ssl.conf
        - 加上Header always set Strict-Transport-Security "max-age=63072000; includeSubdomains; preload"
    - HTTP2
        - LoadModule http2_module modules/mod_http2.so <<記得把註解刪掉
- PHP
    - sudo pkg install php73 php73-mysqli mod_php73 php73-mbstring php73-gd php73-json php73-zlib php73-curl
    - cp /usr/local/etc/php.ini{-production,}
    - rehash
    - vim /usr/local/etc/apache24/Includes/php-fpm.conf
        ```
        <IfModule dir_module>
            DirectoryIndex index.php index.html
            <FilesMatch "\.php$">
                SetHandler application/x-httpd-php</FilesMatch>
        </IfModule>
        ```
    - [BUG網址，但沒用](https://cromwell-intl.com/open-source/google-freebsd-tls/apache-http2-php.html)
        - 只要把Load php module那行註解掉就世界和平
    - Hide php information
        - 編輯 /usr/local/etc/php.ini，將expose_php改為Off
---
- MySQL
    - [安裝參考](https://kifarunix.com/install-mysql-8-on-freebsd-12/)
    - [新增使用者](https://www.opencli.com/mysql/mysql-add-new-users-databases-privileges)
    - Set the transaction isolation levels
        - 在nextcloud中下set transaction isolation level READ COMMITTED;
        - [其他選項解釋](https://ithelp.ithome.com.tw/articles/10194749)
---
- HTTP Applications
    - Basic APP router
        - route: /
            - 直接不符合下面情況就echo這個
        - {A} + {B}
            - 編輯/usr/local/etc/apache24/httpd.conf
              取消註解 LoadModule rewrite_modulelibexec/apache24/mod_rewrite.so
            - 編輯  /usr/local/etc/apache24/extra/httpd-ssl.conf
              在Virtualhost結構下加上:
              - RewriteEngine on
              - RewriteRule /app/([0-9]+\\+[0-9]+) /app/index.php [PT]
            - php 中用 $_SERVER['REQUEST_URI']取得網址，做字串處理
        - app?name={string}
            - $_GET['name']
    - WebSocket
        - 把PDF網址要的兩個檔案都放在wsdemo/下
        - 開terminal跑
            ```
            php -q websockets.php
            ```
        - 用wss連到port 443 然後藉由proxy導到12345
    - NextCloud
        - sudo php occ maintenance:install --database "mysql" --database-name "nextcloud" --database-user "nc" --database-pass "0516075" --admin-user "admin" --admin-pass "0516075"
        - [BUG參考](https://github.com/laradock/laradock/issues/1392)
        - [BUG參考二](https://help.nextcloud.com/t/the-server-requested-authentication-method-unknown-to-the-client/33038/3)
        - BONUS
            - https://help.nextcloud.com/t/solved-well-known-caldav-check-in-13-0-7-explained/38957/20
        - WEBPAGE
            - [rewrite參考](https://medium.com/@awonwon/htaccess-with-rewrite-3dba066aff11)
            - [rewrite參考2](https://blog.hinablue.me/apache-note-about-some-rewrite-note-2011-05/)
            - 用mod_userdir
            - 要把nextcloud/data丟到外面然後改config指到那邊不然會噴錯
            - [噴錯參考](https://github.com/nextcloud/nextcloud-snap/wiki/Change-data-directory-to-use-another-disk-partition?fbclid=IwAR1jyRM5xEgTuknyz4eJXptxOjZk9crp9zmVEJUsGhhPtkqlXiMIyC6010w)
---
- 測試
    - 在nctu.me裡面DNS內容設定IP打網址就會有東西惹
    - curl --http2 https://nctu-sahw4.nctu.me -Ik
    - DEMO要ssh回來改
---