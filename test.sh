while ((a<10))
do
printf '\f'
for((b=0;b<a;b++))
do
printf '#\a'
done
let a++
sleep 1
done
