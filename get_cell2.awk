BEGIN{i=.001;first=1} $1 !~/^#|^0/ {
if(first){ao=$2*$6;first=0}
print i,($2*$6)/ao,$10;i+=.001}
