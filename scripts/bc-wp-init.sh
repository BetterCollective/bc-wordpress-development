#!/bin/bash

cp ./provision/default.yml ./site.yml
while [[ -z $domain ]]; do
    printf "Domain name (eg. promocode.co.ke): "; read domain
done

sed -i -e "/hostname:/s/.*/hostname: $domain/" site.yml

echo -n "Do you want to use PHP 5.6 instead of PHP 7.0 (y/N)?"
read php_ans
if echo "$php_ans" | grep -iq "^y"; then
    sed -i -e "/enable_php56:/s/.*/enable_php56: true/" site.yml
else
    sed -i -e "/enable_php56:/s/.*/enable_php56: false/" site.yml
fi

echo "Evaluating ip address for new vagrant box..."
nextip(){
    IP=$1
    IP_HEX=$(printf '%.2X%.2X%.2X%.2X\n' `echo $IP | sed -e 's/\./ /g'`)
    NEXT_IP_HEX=$(printf %.8X `echo $(( 0x$IP_HEX + 1 ))`)
    NEXT_IP=$(printf '%d.%d.%d.%d\n' `echo $NEXT_IP_HEX | sed -r 's/(..)/0x\1 /g'`)
    echo "$NEXT_IP"
}

# 
if [[ -n `cat /etc/hosts | grep $domain` ]]
then
    ip=`cat /etc/hosts | grep $domain | awk ' { print $1} ' | uniq`     
else
    max_used_ip=`cat /etc/hosts | grep -E '^192.168.33' | awk ' { print $1} ' | sort | uniq | tail -n 1`
    test -n $max_used_ip && ip=$(nextip $max_used_ip) || ip="192.168.33.10"
fi

echo "Address $ip will be used for new vagrant box"
sed -i -e "/^ip:/s/.*/ip: $ip/" site.yml

echo -n "Do you want to work on an existing Wordpress website (y/n)?"
read answer
if echo "$answer" | grep -iq "^y" ;then
    echo -e "\nInstallation steps: "
    echo "1) Run '$ vagrant up' and make sure to provision."
    echo "2) Replace the files from the existing Wordpress application with the files in ./wordpress/, except ./wordpress/phpmyadmin directory."
    echo "3) Login to phpMyAdmin at http://$domain/phpmyadmin, on database 'wordpress', with username 'wordpress' and password 'wordpress', and import your existing database. Make sure your wp-config.php matches these database credentials."
    echo "4) Enjoy developing with your files at ./wordpress/ shared with vm folder /var/www/html, with local access at http://$domain."
else
    printf "Website title: "; read title
    sed -i -e "/title:/s/.*/title: $title/" site.yml

    printf "Website description: "; read description
    sed -i -e "/blogdescription:/s/.*/  blogdescription: $description/" site.yml

    printf "WordPress version (eg. latest): "; read wp_version
    sed -i -e "/version:/s/.*/version: $wp_version/" site.yml

    printf "Wordpress username (eg. admin): "; read wp_username
    sed -i -e "/admin_user:/s/.*/admin_user: $wp_username/" site.yml

    printf "Wordpress password (eg. admin): "; read wp_password
    sed -i -e "/admin_pass:/s/.*/admin_pass: $wp_password/" site.yml

    echo -e "\nInstallation Steps:"
    echo "1) Run '$ vagrant up' and make sure to provision."
    echo "2) Enjoy developing with your files at ./wordpress/ shared with vm folder /var/www/html, with local access at http://$domain."
    echo "3) You can manage the database from phpMyAdmin at http://$domain/phpmyadmin with database 'wordpress', with username 'wordpress' and password 'wordpress'."
fi
