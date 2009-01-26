#!/bin/bash

# CHANGELOG
# 01/26/2009
# hoptoad as a gem
# paperclip as a gem
#
# 01/21/2009
# specify versions of the ipi databases to use
# update to passenger 2.0.6
# update to tandem 08-12-01-1
# update to monit 5beta6
# update to blast 2.2.19
#
# 12/01/2008
# newer base ami doesn't have app-armor
#
# 11/25/2008
# add patch to use Argonne National Laboratory mirror
#
# 11/24/2008
# remove apparmor
#
# 11/17/2008
# back to apache as prep for upload progress
# run the cleanup script by default
#
# 11/14/2008
# use the apt package for ruby/mysql as it's newer than the gem
#
# 11/12/2008
# remove apache, add thin as the web server
#
# 11/11/2008
# do a dist-upgrade for packages
# add beanstalkd 

# build the directory structure
cd /
mkdir pipeline
cd pipeline
mkdir bin
mkdir dbs
cd bin
mkdir tandem

# we need uuencode
apt-get -y update
apt-get -y install sharutils

# patch to make the apt sources.list default to Argonne National Laboratory mirror

cd /etc/apt
uudecode -o patchfile << EOF
begin-base64 644 sources.list
LS0tIHNvdXJjZXMubGlzdF9vbGQJMjAwOC0xMS0yNSAxODoxOTozOC4wMDAw
MDAwMDAgKzAwMDAKKysrIHNvdXJjZXMubGlzdAkyMDA4LTExLTI1IDE4OjIx
OjE1LjAwMDAwMDAwMCArMDAwMApAQCAtMSw4ICsxLDggQEAKLWRlYiBodHRw
Oi8vdXMuYXJjaGl2ZS51YnVudHUuY29tL3VidW50dSBoYXJkeSBtYWluIHJl
c3RyaWN0ZWQgdW5pdmVyc2UgbXVsdGl2ZXJzZQotZGViLXNyYyBodHRwOi8v
dXMuYXJjaGl2ZS51YnVudHUuY29tL3VidW50dSBoYXJkeSBtYWluIHJlc3Ry
aWN0ZWQgdW5pdmVyc2UgbXVsdGl2ZXJzZQorZGViIGh0dHA6Ly9taXJyb3Iu
YW5sLmdvdi9wdWIvdWJ1bnR1LyBoYXJkeSBtYWluIHJlc3RyaWN0ZWQgdW5p
dmVyc2UgbXVsdGl2ZXJzZQorZGViLXNyYyBodHRwOi8vbWlycm9yLmFubC5n
b3YvcHViL3VidW50dS8gaGFyZHkgbWFpbiByZXN0cmljdGVkIHVuaXZlcnNl
IG11bHRpdmVyc2UKIAotZGViIGh0dHA6Ly91cy5hcmNoaXZlLnVidW50dS5j
b20vdWJ1bnR1IGhhcmR5LXVwZGF0ZXMgbWFpbiByZXN0cmljdGVkIHVuaXZl
cnNlIG11bHRpdmVyc2UKLWRlYi1zcmMgaHR0cDovL3VzLmFyY2hpdmUudWJ1
bnR1LmNvbS91YnVudHUgaGFyZHktdXBkYXRlcyBtYWluIHJlc3RyaWN0ZWQg
dW5pdmVyc2UgbXVsdGl2ZXJzZQorZGViIGh0dHA6Ly9taXJyb3IuYW5sLmdv
di9wdWIvdWJ1bnR1LyBoYXJkeS11cGRhdGVzIG1haW4gcmVzdHJpY3RlZCB1
bml2ZXJzZSBtdWx0aXZlcnNlCitkZWItc3JjIGh0dHA6Ly9taXJyb3IuYW5s
Lmdvdi9wdWIvdWJ1bnR1LyBoYXJkeS11cGRhdGVzIG1haW4gcmVzdHJpY3Rl
ZCB1bml2ZXJzZSBtdWx0aXZlcnNlCiAKLWRlYiBodHRwOi8vc2VjdXJpdHku
dWJ1bnR1LmNvbS91YnVudHUgaGFyZHktc2VjdXJpdHkgbWFpbiByZXN0cmlj
dGVkIHVuaXZlcnNlIG11bHRpdmVyc2UKLWRlYi1zcmMgaHR0cDovL3NlY3Vy
aXR5LnVidW50dS5jb20vdWJ1bnR1IGhhcmR5LXNlY3VyaXR5IG1haW4gcmVz
dHJpY3RlZCB1bml2ZXJzZSBtdWx0aXZlcnNlCitkZWIgaHR0cDovL21pcnJv
ci5hbmwuZ292L3B1Yi91YnVudHUvIGhhcmR5LXNlY3VyaXR5IG1haW4gcmVz
dHJpY3RlZCB1bml2ZXJzZSBtdWx0aXZlcnNlCitkZWItc3JjIGh0dHA6Ly9t
aXJyb3IuYW5sLmdvdi9wdWIvdWJ1bnR1LyBoYXJkeS1zZWN1cml0eSBtYWlu
IHJlc3RyaWN0ZWQgdW5pdmVyc2UgbXVsdGl2ZXJzZQo=
====
EOF

patch -p0 < patchfile
rm patchfile


# update the image, install needed packages
apt-get -y update
apt-get -y upgrade
apt-get -y dist-upgrade
DEBIAN_FRONTEND=noninteractive apt-get -y install build-essential libevent-dev autoconf automake zlib1g-dev libxml2-dev libssl-dev ruby1.8-dev irb1.8 irb rdoc1.8 libmysql-ruby1.8 libreadline-ruby1.8 flex bison rubygems git-core apache2 mysql-server libmysqlclient15-dev apache2-prefork-dev libxml-smart-perl libxml-simple-perl libxml-sax-expat-perl libyaml-perl libarchive-zip-perl libtext-csv-perl
apt-get -y autoremove

#download and build beanstalkd
cd /usr/local/src
git clone git://github.com/kr/beanstalkd.git  
cd beanstalkd
chmod 775 buildconf.sh
./buildconf.sh
./configure
make
mv beanstalkd /usr/local/bin/

# download and copy formatdb
cd /usr/local/src
wget ftp://ftp.ncbi.nih.gov/blast/executables/LATEST/blast-2.2.19-ia32-linux.tar.gz
tar xvfz blast-2.2.19-ia32-linux.tar.gz
cd blast-2.2.19
cp bin/formatdb /usr/local/bin/

# download and build tandem
cd /usr/local/src
wget ftp://ftp.thegpm.org/projects/tandem/source/tandem-ubuntu-08-12-01-1.tar.gz
tar xvfz tandem-ubuntu-08-12-01-1.tar.gz 
cd tandem-ubuntu-08-12-01-1/src
cp Makefile_ubuntu_32 Makefile
make
cp ../bin/* /pipeline/bin/tandem
cd /pipeline/bin/tandem
rm input.xml
rm taxonomy.xml
ln -s /pipeline/vipdac/config/tandem_config/taxonomy.xml /pipeline/bin/tandem/
rm *.css
rm *.xsl
rm fasta_pro.exe
rm test_spectra.mgf

# download and move OMSSA
cd /usr/local/src
wget ftp://ftp.ncbi.nih.gov/pub/lewisg/omssa/CURRENT/omssa-linux.tar.gz
tar xvfz omssa-linux.tar.gz
mv omssa-2.1.4.linux/ /pipeline/bin/
ln -s /pipeline/bin/omssa-2.1.4.linux /pipeline/bin/omssa
cd /pipeline/bin/omssa
rm MSHHWGYGK.dta
rm omssamerge
rm omssa2pepXML

uudecode -o patchfile << EOF
begin-base64 644 mods.xml
LS0tIG1vZHMueG1sCTIwMDgtMTAtMTUgMTU6MzI6MzYuMDAwMDAwMDAwICsw
MDAwCisrKyBtb2RzX25ldy54bWwJMjAwOC0xMC0xNSAxNToyMDoyMy4wMDAw
MDAwMDAgKzAwMDAKQEAgLTEsNyArMSwxMCBAQAogPD94bWwgdmVyc2lvbj0i
MS4wIj8+Ci08IURPQ1RZUEUgTVNNb2RTcGVjU2V0IFBVQkxJQyAiLS8vTkNC
SS8vT01TU0EvRU4iICJPTVNTQS5kdGQiPgotPE1TTW9kU3BlY1NldD4KLSAg
PE1TTW9kU3BlYz4KKyAgPE1TTW9kU3BlY1NldAorICAgIHhtbG5zPSJodHRw
Oi8vd3d3Lm5jYmkubmxtLm5paC5nb3YiCisgICAgeG1sbnM6eHM9Imh0dHA6
Ly93d3cudzMub3JnLzIwMDEvWE1MU2NoZW1hLWluc3RhbmNlIgorICAgIHhz
OnNjaGVtYUxvY2F0aW9uPSJodHRwOi8vd3d3Lm5jYmkubmxtLm5paC5nb3Yg
T01TU0EueHNkIgorPgorPE1TTW9kU3BlYz4KICAgICA8TVNNb2RTcGVjX21v
ZD4KICAgICAgIDxNU01vZCB2YWx1ZT0ibWV0aHlsayI+MDwvTVNNb2Q+CiAg
ICAgPC9NU01vZFNwZWNfbW9kPgo=
====
EOF
patch -p0 < patchfile
rm patchfile

# link the apache config
rm /etc/apache2/sites-available/default
ln -s /pipeline/vipdac/config/apache.conf /etc/apache2/sites-available/default

cd /usr/local/src
git clone git://github.com/drogus/apache-upload-progress-module.git
cd apache-upload-progress-module
apxs2 -c -i mod_upload_progress.c

# download and build monit
cd /usr/local/src
wget http://mmonit.com/monit/dist/beta/monit-5.0_beta6.tar.gz
tar xvfz monit-5.0_beta6.tar.gz
cd monit-5.0_beta6
./configure
make
make install
cd /etc/

# generate the monitrc file
uudecode -o monitrc << EOF
begin-base64 700 monitrc
c2V0IGRhZW1vbiAzMCAjIFBvbGwgYXQgMzAgc2Vjb25kIGludGVydmFscwpz
ZXQgbG9nZmlsZSBzeXNsb2cKCmluY2x1ZGUgL2V0Yy9tb25pdC8qCg==
====
EOF

# set monitrc to the proper permissions, link the config file
chmod 700 monitrc
mkdir monit
cd monit
ln -s /pipeline/vipdac/config/node.monitrc /etc/monit

# symlink the rc.local script
rm -rf /etc/rc.local
ln -s /pipeline/vipdac/config/rc_local /etc/rc.local

# link the initd files for the node
cd /etc/init.d
ln -s /pipeline/vipdac/config/init-d-node node

# add the amazon-user-data.local to /etc/hosts
echo "169.254.169.254 amazon-user-data.local" >> /etc/hosts

# update to rubygems 1.3.1
gem update --system
gem update --system
gem update --system

mv /usr/bin/gem /usr/bin/gem.OLD
ln -s /usr/bin/gem1.8 /usr/bin/gem
  
# install ruby gems used by the application
# double up just to catch any timeout errors
gem install right_aws --no-rdoc --no-ri
gem install right_aws --no-rdoc --no-ri
gem install libxml-ruby --no-rdoc --no-ri
gem install libxml-ruby --no-rdoc --no-ri
gem install rubyzip --no-rdoc --no-ri
gem install rubyzip --no-rdoc --no-ri
gem install rails --no-rdoc --no-ri
gem install rails --no-rdoc --no-ri
gem install rubyist-aasm --source http://gems.github.com/ --no-rdoc --no-ri
gem install rubyist-aasm --source http://gems.github.com/ --no-rdoc --no-ri
gem install mislav-will_paginate --source http://gems.github.com/ --no-rdoc --no-ri
gem install mislav-will_paginate --source http://gems.github.com/ --no-rdoc --no-ri
gem install thoughtbot-paperclip --source http://gems.github.com/ --no-rdoc --no-ri
gem install thoughtbot-paperclip --source http://gems.github.com/ --no-rdoc --no-ri
gem install rspec --no-rdoc --no-ri
gem install rspec --no-rdoc --no-ri
gem install rspec-rails --no-rdoc --no-ri
gem install rspec-rails --no-rdoc --no-ri
gem install hoe --no-rdoc --no-ri
gem install hoe --no-rdoc --no-ri
gem install beanstalk-client --no-rdoc --no-ri
gem install beanstalk-client --no-rdoc --no-ri
gem install passenger --no-rdoc --no-ri
gem install passenger --no-rdoc --no-ri
gem install ruby-debug --no-rdoc --no-ri
gem install ruby-debug --no-rdoc --no-ri
gem install uuidtools --no-rdoc --no-ri
gem install uuidtools --no-rdoc --no-ri

# install the ruby/apache bridge (this will feed the enters to run it from a script)
passenger-install-apache2-module << EOF


EOF

# download the application from github
cd /pipeline/
git clone git://github.com/mcwbbc/vipdac.git
ln -s /pipeline/vipdac/config/database_sample.yml /pipeline/vipdac/config/database.yml
chown -R www-data:www-data /pipeline/vipdac

# download, unpack and formatdb the protein databases
cd /pipeline/dbs
wget ftp://ftp.ebi.ac.uk/pub/databases/IPI/old/HUMAN/ipi.HUMAN.v3.54.fasta.gz
wget ftp://ftp.ebi.ac.uk/pub/databases/IPI/old/MOUSE/ipi.MOUSE.v3.54.fasta.gz
wget ftp://ftp.ebi.ac.uk/pub/databases/IPI/old/RAT/ipi.RAT.v3.54.fasta.gz
wget ftp://ftp.ebi.ac.uk/pub/databases/integr8/fasta/proteomes/25.H_sapiens.fasta.gz
wget ftp://ftp.ebi.ac.uk/pub/databases/integr8/fasta/proteomes/59.M_musculus.fasta.gz
wget ftp://ftp.ebi.ac.uk/pub/databases/integr8/fasta/proteomes/122.R_norvegicus.fasta.gz
wget ftp://ftp.ebi.ac.uk/pub/databases/integr8/fasta/proteomes/40.S_cerevisiae_ATCC_204508.fasta.gz
wget ftp://ftp.ebi.ac.uk/pub/databases/integr8/fasta/proteomes/18.E_coli_K12.fasta.gz
wget http://downloads.yeastgenome.org/sequence/genomic_sequence/orf_protein/orf_trans.fasta.gz
gunzip ipi.HUMAN.v3.54.fasta.gz
gunzip ipi.MOUSE.v3.54.fasta.gz
gunzip ipi.RAT.v3.54.fasta.gz
gunzip 25.H_sapiens.fasta.gz
gunzip 59.M_musculus.fasta.gz
gunzip 122.R_norvegicus.fasta.gz
gunzip 40.S_cerevisiae_ATCC_204508.fasta.gz
gunzip 18.E_coli_K12.fasta.gz
gunzip orf_trans.fasta.gz

perl /pipeline/vipdac/lib/reformat_db.pl 25.H_sapiens.fasta 25.H_sapiens.fasta-rev
perl /pipeline/vipdac/lib/reformat_db.pl 59.M_musculus.fasta 59.M_musculus.fasta-rev
perl /pipeline/vipdac/lib/reformat_db.pl 122.R_norvegicus.fasta 122.R_norvegicus.fasta-rev
perl /pipeline/vipdac/lib/reformat_db.pl 40.S_cerevisiae_ATCC_204508.fasta 40.S_cerevisiae_ATCC_204508.fasta-rev
perl /pipeline/vipdac/lib/reformat_db.pl 18.E_coli_K12.fasta 18.E_coli_K12.fasta-rev

/usr/local/bin/formatdb -i ipi.HUMAN.v3.54.fasta -o T -n ipi.HUMAN.v3.54
/usr/local/bin/formatdb -i ipi.MOUSE.v3.54.fasta -o T -n ipi.MOUSE.v3.54
/usr/local/bin/formatdb -i ipi.RAT.v3.54.fasta -o T -n ipi.RAT.v3.54
/usr/local/bin/formatdb -i orf_trans.fasta -o T -n orf_trans

/usr/local/bin/formatdb -i 25.H_sapiens.fasta-rev -o T -n 25.H_sapiens
/usr/local/bin/formatdb -i 59.M_musculus.fasta-rev -o T -n 59.M_musculus
/usr/local/bin/formatdb -i 122.R_norvegicus.fasta-rev -o T -n 122.R_norvegicus
/usr/local/bin/formatdb -i 40.S_cerevisiae_ATCC_204508.fasta-rev -o T -n 40.S_cerevisiae_ATCC_204508
/usr/local/bin/formatdb -i 18.E_coli_K12.fasta-rev -o T -n 18.E_coli_K12

# create database conversions for ez2 processing
/pipeline/vipdac/lib/convert_databases.pl --input=/pipeline/dbs/25.H_sapiens.fasta --type=ebi
/pipeline/vipdac/lib/convert_databases.pl --input=/pipeline/dbs/59.M_musculus.fasta --type=ebi
/pipeline/vipdac/lib/convert_databases.pl --input=/pipeline/dbs/122.R_norvegicus.fasta --type=ebi
/pipeline/vipdac/lib/convert_databases.pl --input=/pipeline/dbs/40.S_cerevisiae_ATCC_204508.fasta --type=ebi
/pipeline/vipdac/lib/convert_databases.pl --input=/pipeline/dbs/18.E_coli_K12.fasta --type=ebi

/pipeline/vipdac/lib/convert_databases.pl --input=/pipeline/dbs/ipi.HUMAN.v3.54.fasta --type=ipi
/pipeline/vipdac/lib/convert_databases.pl --input=/pipeline/dbs/ipi.MOUSE.v3.54.fasta --type=ipi
/pipeline/vipdac/lib/convert_databases.pl --input=/pipeline/dbs/ipi.RAT.v3.54.fasta --type=ipi

/pipeline/vipdac/lib/cleanup_image.sh

