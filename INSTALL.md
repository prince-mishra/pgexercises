sudo docker build -t pgexercises .
sudo docker run -itd --name pgexercises -p 25432:5432 -p 20800:80 pgexercises

# exec into the cotainer and run
cd /pgexercises/scripts
./processdocs.pl ../ 1
