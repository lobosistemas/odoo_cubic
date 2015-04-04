# Script para iniciar servidor Gevent OpenERP
odoo/openerp-gevent  -c .openerp_serverrc --db-filter="^%d$" --logfile=log/openerp-gevent.log --pidfile=.oerev.pid &
