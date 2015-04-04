# Script para iniciar el servidor gevent OpenERP
odoo/openerp-gevent  -c .openerp_serverrc --db-filter="^%d$" --logfile=log/openerp-gevent.log --pidfile=.oerev.pid &
