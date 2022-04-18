BEGIN{i=.001;first=1} $1 !~/^#|^0/ {
if(first){ao=14400;first=0}
print i,($2*$6)/ao,$10;i+=.001}


#The 14400 was obtained after the multiplication of the cell dimension which was 120. hence 120*120
