GUIA DE INSTALACIÓN EN UBUNTU
=============================

Instalación de librerías Python

    $ sudo apt-get update
    $ sudo apt-get install python-docutils python-gdata python-mako python-dateutil python-feedparser python-lxml python-tz python-vatnumber python-webdav python-xlwt python-werkzeug python-yaml python-zsi python-unittest2 python-mock python-libxslt1 python-ldap python-reportlab python-pybabel python-pychart python-simplejson python-psycopg2 python-vobject python-openid python-setuptools bzr postgresql unixodbc unixodbc-dev python-pyodbc python-psutil nginx git wkhtmltopdf python-gevent
    $ sudo easy_install jinja2 CubicReport decorator requests pyPdf openerp-client-lib openerp-client-etl gunicorn passlib psycogreen


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
    ## Inicializa los submodulos para odoo y branch ##
    $ git submodule init
    ## Actualiza los submodulos, es decir los directorios odoo y branch ##
    $ git submodule update


Para actualizar los repositorios poner los siguientes comandos:

    ## Actualiza el directorio actual de su repositorio privado, es decir "src" ##
    $ git pull 
    ## Para abrir la versión 8.0 del repositorio ##
    $ git checkout 8.0
    $ git submodule foreach git checkout 8.0
    ## Limpia posibles archivos temporales
    $ git clean -d -f
    $ git submodule foreach git clean -d -f


Generación del archivo de configuración

    $ odoo/openerp-server -s
    $ cp ~/.openerp_serverrc .


Modificación del archivo de configuración (asignación de puertos)

    $ vi .openerp_serverrc
    -------------------------------------------
    [options]
    addons_path = ./odoo/addons,./trunk,./branch 
    ...
    data_dir = ./data
    ...
    xmlrpc = True
    xmlrpc_interface =
    xmlrpc_port = 8069
    xmlrpcs = True
    xmlrpcs_interface =
    xmlrpcs_port = 8071
    -------------------------------------------


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
    $ sudo rm /etc/nginx/sites-enabled/default

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

    $ wget https://bitbucket.org/zhb/iredmail/downloads/iRedMail-0.9.0.tar.bz2
    $ tar -zjvf iRedMail-0.9.0.tar.bz2
    $ cd iRedMail
    $ bash iRedMail.sh
    
Configuración del Postfix

    $ sudo vi /etc/postfix/main.cf
    ---------------------------------------------
    ...
    mynetworks = 127.0.0.0/8 <ip_del_open>/32
    ...
    ---------------------------------------------
    $sudo service postfix restart
    
Configuración DNS

    1. Ingresar el registro MX de su dominio, el cual debe apuntar a un host con el DNS reverso (PTR) activado en ip4 y ip6
    2. Agregar el registro TXT spf para su dominio, ejemplo del TXT:
        v=spf1 ip4:66.175.218.31 ip6:2600:3c01::f03c:91ff:fe18:293f ip4:173.230.150.187 ip6:2600:3c01::f03c:91ff:fe50:2bdd ip4:50.116.8.92 ip6:2600:3c01::f03c:91ff:fe50:c395 ~all
    3. Agregar el registro TXT DKIM para la encriptación de ls correos
        3.1 Para obtener llave ejecutar y el valor del TXT:
            $ amavis-new showkeys
        3.2 Registrar la llave obtenida en el registro TXT del nombre dkim._domainkey.<tu.dominio> ejemplo del TXT:
            v=DKIM1; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCx/BKIq6ZRAiQkAPNcH+53SIp95b9xmjL2O5tebay2trbjJnuF+6hl8R4BaRIgscH7DqS4P5irlb8buD6XDPD7ubOWZvevJdbVKyVKerVZAM1nMVCP6Rt+wtz+mL06l6qZA/WhW9YCtWREaAtOAJJhy8hKNikwvRE/8uimmEkmPQIDAQAB
        3.3 Verificar si la llave fue cargada correctamente
            $ amavis-new testkeys
    4. Agregar el registro TXT DMARC para la validación del spf y DKIM, el nombre debe ser _dmarc.<tu.dominio> ejemplo del TXT:
        v=DMARC1; p=quarantine; pct=100; rua=mailto:isp@lapaginaweb.com; ruf=mailto:isp@lapaginaweb.com

Ingresar a https://<ip_del_correo>/iredadmin/ y registrar al usuario catchall@<-dominio_alias_del_openerp->


Ingresar al OpenERP con usuario administrador y realizar las siguientes tareas:

    1. Ingresar al menú "Configuración > Configuración > Configuraciones Generales" y actualizar el <dominio_alias_del_openerp>
    2. Ingresar al enlace "Configurar la pasarela de correo electrónico entrante" y registrar los datos para descargar el correo de catchall@<dominio_alias_del_openerp> via pop3/imap con SSL/TLS, registrar solo los campos obligatorios.
    3. Ingresar al enlace "Configurar servidores de correo saliente" y registrar los datos de la cuenta para enviar correo electrónico, puede utilizarce la misma cuenta catchall@<dominio_alias_del_openerp>, utilizar el puerto 25 y la "seguridad de conexión" TLS /STARTTLS)
    4. Para vincular las cuentas de correos que se crean en https://<ip_del_correo>/iredadmin/ con los usuarios de OpenERP se debe de configurar los alias de los usuarios en el menú de usuarios o si tienen varios alias en el menú "Configuración > Técnico > Email > Alias"
