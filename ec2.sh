apt-get update
apt-get install -y git apache2 libapache2-mod-wsgi-py3 python3 python3-pip
git clone https://git.dyakov.space/hse-se/devops_1-apache_vagrant /vagrant
pip3 install flask
chown -R root:root /vagrant
rm -rf /etc/apache2/sites-available
rm -rf /etc/apache2/sites-enabled
mkdir -p /etc/apache2/sites-enabled
cp -r /vagrant/config/apache /etc/apache2/sites-available
a2ensite simple-site.conf wsgi-site.conf
systemctl restart apache2
