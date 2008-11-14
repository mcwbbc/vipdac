#!/bin/bash

# CHANGELOG
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

# update the image, install needed packages
apt-get -y update
apt-get -y upgrade
apt-get -y dist-upgrade
DEBIAN_FRONTEND=noninteractive apt-get -y install build-essential libevent-dev autoconf automake zlib1g-dev libxml2-dev libssl-dev ruby1.8-dev irb1.8 irb rdoc1.8 libmysql-ruby1.8 libreadline-ruby1.8 sharutils flex bison rubygems git-core mysql-server libmysqlclient15-dev libxml-smart-perl libxml-simple-perl libxml-sax-expat-perl libyaml-perl libarchive-zip-perl libtext-csv-perl

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
wget ftp://ftp.ncbi.nih.gov/blast/executables/LATEST/blast-2.2.18-ia32-linux.tar.gz
tar xvfz blast-2.2.18-ia32-linux.tar.gz
cd blast-2.2.18
cp bin/formatdb /usr/local/bin/

# download and build tandem
cd /usr/local/src
wget ftp://ftp.thegpm.org/projects/tandem/source/tandem-linux-08-02-01-3.tar.gz
tar xvfz tandem-linux-08-02-01-3.tar.gz 
ln -s /usr/lib/libexpat.so.1 /usr/lib/libexpat.so.0
cd tandem-linux-08-02-01-3/src
cp Makefile_ubuntu Makefile

uudecode -o patchfile << EOF
begin-base64 644 patch
LS0tIE1ha2VmaWxlX3VidW50dQkyMDA4LTA1LTIyIDE1OjM5OjEyLjAwMDAw
MDAwMCArMDAwMAorKysgTWFrZWZpbGUJMjAwOC0wOS0xMiAxMzoyNjozMy4w
MDAwMDAwMDAgKzAwMDAKQEAgLTE1LDcgKzE1LDcgQEAKICNDWFhGTEFHUyA9
IC1PMiAtREdDQzQgLURQTFVHR0FCTEVfU0NPUklORyAtRFhfUDMNCiAKICN1
YnVudHUgNjQgYml0IHZlcnNpb24NCi1MREZMQUdTID0gIC1scHRocmVhZCAt
TC91c3IvbGliNjQgL3Vzci9saWI2NC9saWJleHBhdC5zby4wDQorTERGTEFH
UyA9ICAtbHB0aHJlYWQgLUwvdXNyL2xpYiAvdXNyL2xpYi9saWJleHBhdC5z
by4wDQogDQogU1JDUyA6PSAkKHdpbGRjYXJkICouY3BwKQ0KIE9CSlMgOj0g
JChwYXRzdWJzdCAlLmNwcCwlLm8sJCh3aWxkY2FyZCAqLmNwcCkpDQo=
====
EOF

patch -p0 < patchfile
rm patchfile

make
cp ../bin/* /pipeline/bin/tandem
cd /pipeline/bin/tandem
rm input.xml
rm taxonomy.xml
ln -s /pipeline/vipdac/config/tandem_config/taxonomy.xml /pipeline/bin/tandem/
rm *.css
rm *.xsl
rm p3.exe
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

# download and build monit
cd /usr/local/src
wget http://mmonit.com/monit/dist/beta/monit-5.0_beta4.tar.gz
tar xvfz monit-5.0_beta4.tar.gz
cd monit-5.0_beta4
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

# update to rubygems 1.2 (1.3 causes issues)
cd /usr/local/src
wget http://rubyforge.org/frs/download.php/38646/rubygems-1.2.0.tgz
tar xvfz rubygems-1.2.0.tgz
cd rubygems-1.2.0
ruby setup.rb

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
gem install rubyist-aasm mislav-will_paginate --source http://gems.github.com/ --no-rdoc --no-ri
gem install rspec --no-rdoc --no-ri
gem install rspec --no-rdoc --no-ri
gem install rspec-rails --no-rdoc --no-ri
gem install rspec-rails --no-rdoc --no-ri
gem install hoe --no-rdoc --no-ri
gem install hoe --no-rdoc --no-ri
gem install beanstalk-client --no-rdoc --no-ri
gem install beanstalk-client --no-rdoc --no-ri
gem install thin --no-rdoc --no-ri
gem install thin --no-rdoc --no-ri
gem install ruby-debug --no-rdoc --no-ri
gem install ruby-debug --no-rdoc --no-ri

# download the application from github
cd /pipeline/
git clone git://github.com/mcwbbc/vipdac.git
ln -s /pipeline/vipdac/config/database_sample.yml /pipeline/vipdac/config/database.yml
chown -R www-data:www-data /pipeline/vipdac

# download, unpack and formatdb the protein databases
cd /pipeline/dbs
wget ftp://ftp.ebi.ac.uk/pub/databases/IPI/current/ipi.HUMAN.fasta.gz
wget ftp://ftp.ebi.ac.uk/pub/databases/IPI/current/ipi.MOUSE.fasta.gz
wget ftp://ftp.ebi.ac.uk/pub/databases/IPI/current/ipi.RAT.fasta.gz
wget ftp://ftp.ebi.ac.uk/pub/databases/integr8/fasta/proteomes/25.H_sapiens.fasta.gz
wget ftp://ftp.ebi.ac.uk/pub/databases/integr8/fasta/proteomes/59.M_musculus.fasta.gz
wget ftp://ftp.ebi.ac.uk/pub/databases/integr8/fasta/proteomes/122.R_norvegicus.fasta.gz
wget ftp://ftp.ebi.ac.uk/pub/databases/integr8/fasta/proteomes/40.S_cerevisiae_ATCC_204508.fasta.gz
wget ftp://ftp.ebi.ac.uk/pub/databases/integr8/fasta/proteomes/18.E_coli_K12.fasta.gz
wget http://downloads.yeastgenome.org/sequence/genomic_sequence/orf_protein/orf_trans.fasta.gz
gunzip ipi.HUMAN.fasta.gz
gunzip ipi.MOUSE.fasta.gz
gunzip ipi.RAT.fasta.gz
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

/usr/local/bin/formatdb -i ipi.HUMAN.fasta -o T -n ipi.HUMAN
/usr/local/bin/formatdb -i ipi.MOUSE.fasta -o T -n ipi.MOUSE
/usr/local/bin/formatdb -i ipi.RAT.fasta -o T -n ipi.RAT
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

/pipeline/vipdac/lib/convert_databases.pl --input=/pipeline/dbs/ipi.HUMAN.fasta --type=ipi
/pipeline/vipdac/lib/convert_databases.pl --input=/pipeline/dbs/ipi.MOUSE.fasta --type=ipi
/pipeline/vipdac/lib/convert_databases.pl --input=/pipeline/dbs/ipi.RAT.fasta --type=ipi

