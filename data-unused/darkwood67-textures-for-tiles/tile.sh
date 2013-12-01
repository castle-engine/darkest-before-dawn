for i in *jpg; do
echo "$i"
montage "$i" "$i" "$i" "$i" "$i" "$i" "$i" "$i" "$i" -geometry 10%x10%+0+0 out "${i%.jpg}-tile.jpg"
echo done
done
