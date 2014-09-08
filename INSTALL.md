GUIA DE INSTALACIÓN EN UBUNTU
=============================

Instalación de librerías Python

    $ sudo apt-get install python-docutils python-gdata python-mako python-dateutil python-feedparser python-lxml python-tz python-vatnumber python-webdav python-xlwt python-werkzeug python-yaml python-zsi python-unittest2 python-mock python-libxslt1 python-ldap python-reportlab python-pybabel python-pychart python-simplejson python-psycopg2 python-vobject python-openid python-setuptools bzr postgresql unixodbc unixodbc-dev python-pyodbc python-psutil nginx git wkhtmltopdf
    $ sudo easy_install jinja2
    $ sudo easy_install decorator
    $ sudo easy_install requests
    $ sudo easy_install CubicReport
    $ sudo easy_install openerp-client-lib
    $ sudo easy_install openerp-client-etl
    $ sudo easy_install gunicorn


Creación del usuario de base de datos

    $ sudo su - postgres
    $ createuser -d -R -S cubicerp
    $ exit


Creación de usuario que contendrá al branch sincronizado

    $ sudo useradd cubicerp -m -s /bin/bash
    $ sudo su - cubicerp


Descarga de repositorios, preguntar el nombre se le puso a su repositorio privado (<tu_empresa>)

    $ git clone https://github.com/CubicERP/<tu_empresa>.git src
    $ cd src
    $ git submodule init
    $ git submodule update


Para actualizar los repositorios poner los siguientes comandos:

    ## Actualiza el directorio actual de su repositorio privado, es decir "src" ##
    $ git pull 
    ## Actualiza los submodulos, es decir los directorios odoo y branch ##
    $ git submodule update
    ## Para abrir la versión 7.0 del repositorio ##
    $ git checkout 7.0
    $ git submodule foreach git checkout 7.0


Modificación del archivo de configuración (asignación de puertos)

    $ vi .openerp_serverrc


Los comandos para iniciar y parar el servicio del OpenERP en desarrollo con Werkzeugh

    $ ./stop.sh
    $ ./start.sh


Los comandos para iniciar y reiniciar el servicio del OpenERP en producción con gunicorn

    $ ./gstart.sh
    $ ./grestart.sh


Agregando inicio automatico del servicio

    $ sudo vi /etc/rc.local
    -------------------------------------------
    sudo su - cubicerp -c "cd src;./start.sh"
    sudo su - cubicerp -c "cd src;./gstart.sh"
    -------------------------------------------

Una vez iniciado el servicio para probar la instalación utilizar el siguiente url:

    http://<tu-ip>:18069 


Comandos para actualización  de la base de datos

    $ cd src
    $ odoo/openerp-server -c .openerp_serverrc -d <base_de_datos> -u all


Instalación del Gunicorn + NGINX
--------------------------------

Debe conectarse con un usuario con permisos de ejecutar sudo

Generación de certificado SSL

    $ cd /etc/nginx/
    $ sudo mkdir ssl
    $ cd /etc/nginx/ssl
    $ sudo openssl genrsa -des3 -out openerp.pkey 1024

Elimina la clave del certificado ssl

    $ sudo openssl rsa -in openerp.pkey -out openerp.key

Firmando el certificado ssl

    $ sudo openssl req -new -key openerp.key -out openerp.csr
    $ sudo openssl x509 -req -days 730 -in openerp.csr -signkey openerp.key -out openerp.crt
    $ cd ..

Configurando NGINX

    $ sudo vi /etc/nginx/sites-available/openerp
    ---------------------------------------------
    server {
          listen   443;
          server_name 0.0.0.0;
  
          access_log  /var/log/nginx/openerp-access.log;
          error_log   /var/log/nginx/openerp-error.log;
  
          ssl on;
          ssl_certificate     /etc/nginx/ssl/openerp.crt;
          ssl_certificate_key /etc/nginx/ssl/openerp.key;
  
          location / {
                  proxy_pass http://127.0.0.1:8078;
          }
  
    }
    server {
          listen   80;
          server_name 0.0.0.0;
  
          access_log  /var/log/nginx/openerp-access.log;
          error_log   /var/log/nginx/openerp-error.log;
  
          location / {
                  proxy_pass http://127.0.0.1:8078;
          }
  
    }
    ---------------------------------------------
    $ sudo ln -s /etc/nginx/sites-available/openerp /etc/nginx/sites-enabled/openerp

Reiniciando NGINX

    $ sudo service nginx restart

Agregando PYTHONPATH

    $ sudo vi /etc/environment
    ---------------------------------------------
    ...
    PYTHONPATH=.
    ---------------------------------------------

Actualizar los parámetros del OpenERP

    $ sudo su - cubicerp
    $ cd src/odoo
    $ vi openerp-wsgi.py
    ---------------------------------------------
    ...
    conf['addons_path'] = './addons,../branch,../trunk'
    ...
    bind = '127.0.0.1:8078'
    pidfile = '.gunicorn.pid'
    workers = 7
    timeout = 240
    max_requests = 2000
    ---------------------------------------------

Iniciando el Gunicorn

    $ gunicorn openerp:service.wsgi_server.application -c openerp-wsgi.py

Instalación Servidor de Correos
-------------------------------

Instalando el iRedMail

    $ wget https://bitbucket.org/zhb/iredmail/downloads/iRedMail-0.8.7.tar.bz2
    $ tar -zjvf iRedMail-0.8.7.tar.bz2
    $ cd iRedMail
    $ bash iRedMail.sh
    
Configuración del Postfix

    $ sudo vi /etc/postfix/main.cf
    ---------------------------------------------
    ...
    mynetworks = 127.0.0.0/8 <ip_del_open>/32
    smtpd_reject_unlisted_sender = no
    smtpd_recipient_restrictions = reject_unknown_sender_domain, reject_unknown_recipient_domain, reject_non_fqdn_sender, reject_non_fqdn_recipient, reject_unlisted_recipient, check_policy_service inet:127.0.0.1:7777, check_policy_service inet:127.0.0.1:10031, permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination
    ...
    ---------------------------------------------
    $sudo service postfix restart
    
Configuración del Greylist

    $ mysql -u root -p
    mysql> use cluebringer
    mysql> insert into greylisting_whitelist values (26,'SenderIP:<ip_del_open>','OpenERP',0);
    mysql> \q
    $ sudo service postfix-cluebringer restart

Ingresar a https://<ip_del_correo>/iredadmin/ y registrar al usuario catchall@<dominio_alias_del_openerp>

Ingresar al OpenERP con usuario administrador y realizar las siguientes tareas:

    1. Ingresar al menú "Configuración > Configuración > Configuraciones Generales" y actualizar el <dominio_alias_del_openerp>
    2. Ingresar al enlace "Configurar la pasarela de correo electrónico entrante" y registrar los datos para descargar el correo de catchall@<dominio_alias_del_openerp> via pop3/imap con SSL/TLS, registrar solo los campos obligatorios.
    3. Ingresar al enlace "Configurar servidores de correo saliente" y registrar los datos de la cuenta para enviar correo electrónico, puede utilizarce la misma cuenta catchall@<dominio_alias_del_openerp>, utilizar el puerto 25 y la "seguridad de conexión" TLS /STARTTLS)
    4. Para vincular las cuentas de correos que se crean con el https://<ip_del_correo>/iredadmin/ con los usuarios de OpenERP se debe de configurar los alias de los usuarios en el menú de usuarios o si tienen varios alias en el menú "Configuración > Técnico > Email > Alias"
