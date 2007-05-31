#!/bin/sh
#	$Id: cartesian.sh,v 1.7 2007-05-31 02:51:31 pwessel Exp $
#
# Tests project in Cartesian manipulations

echo -n "$0: Test project for rotating Cartesian data:			"
cat << EOF > azim.$$
30
135
200
290
EOF
cat << EOF > pts.$$
1.7	1
-1	1.5
-1.5	-1.3
1.5	-0.5
EOF
cat << EOF >> axes.$$
> x-axis
-3	0
3	0
> y-axis
0	-3
0	3
EOF
cx=0
cy=0
#
makeproj () {
# Expects azimuth cx cy x y
echo "$4 $5" | project -N -C$2/$3 -A$1 -Fpqrs
}
makeaxis () {
# Expects azimuth cx cy file
project -N -C$2/$3 -A-$1 -Fpq $4 -M
}

pstext -R0/8.5/0/11 -Jx1i -P -Xa0 -Ya0 -K  --CHAR_ENCODING=ISOLatin1+ --HEADER_FONT_SIZE=10 << EOF > cartesian.ps
4.25 10.25 14 0 0 CB [x,y] (black dot). 2nd pair is (p,q) and third is (r,s) [plotted as red dot]
EOF
ypos=1.25
By=Sn
while read az; do
	xpos=0.75
	az90=`gmtmath -Q $az 90 ADD =`
	Bx=We
	while read x y; do
		makeproj $az $cx $cy $x $y > $$.d
		psbasemap -R-2/2/-2/2 -JX1.5i -B2g1${Bx}${By} -O -K -Xa$xpos -Ya$ypos >> cartesian.ps
		echo "0 0 $az 0" | psxy -R -J -O -K -SW0.2 -W0.25p -Xa$xpos -Ya$ypos >> cartesian.ps
		makeaxis $az $cx $cy axes.$$ | psxy -R -J -O -K -M -W1p,red -Xa$xpos -Ya$ypos >> cartesian.ps
		echo "$cx $cy $az 0.75" | psxy -R -J -O -K -SV0.01/0.15/0.1 -Gred -Xa$xpos -Ya$ypos >> cartesian.ps
		echo "$cx $cy $az90 0.75" | psxy -R -J -O -K -SV0.01/0.15/0.1 -Gred -Xa$xpos -Ya$ypos >> cartesian.ps
		makeproj -$az $cx $cy 1.75 0 > $$.x
		makeproj -$az $cx $cy 0 1.75 > $$.y
		awk '{printf "%s %s 7 %s 0 CM P\n", $1, $2, "'$az'"}'   $$.x | pstext -R -J -O -K -A -Xa$xpos -Ya$ypos >> cartesian.ps
		awk '{printf "%s %s 7 %s 0 CM Q\n", $1, $2, "'$az90'"}' $$.y | pstext -R -J -O -K -A -Xa$xpos -Ya$ypos >> cartesian.ps
		echo "$cx $cy 0 0.75" | psxy -R -J -O -K -SV0.01/0.15/0.1 -Gblack -Xa$xpos -Ya$ypos >> cartesian.ps
		echo "$cx $cy 90 0.75" | psxy -R -J -O -K -SV0.01/0.15/0.1 -Gblack -Xa$xpos -Ya$ypos >> cartesian.ps
		echo "1.75 0 7 0 0 CM x" | pstext -R -J -O -K -Gwhite -Xa$xpos -Ya$ypos >> cartesian.ps
		echo "0 1.8 7 0 0 CM y"  | pstext -R -J -O -K -Gwhite -Xa$xpos -Ya$ypos >> cartesian.ps
		awk '{printf ">\n%s %s\n%s %s\n", "'$x'", "'$y'", $3, $4}' $$.d | psxy -R -J -O -K -M -W0.5p,- -Xa$xpos -Ya$ypos >> cartesian.ps
		echo $x $y | psxy -R -J -O -K -Xa$xpos -Ya$ypos -Sc0.075i -Gblack >> cartesian.ps
		cut -f3,4 $$.d | psxy -R -J -O -K -Xa$xpos -Ya$ypos -Sc0.075i -Gred >> cartesian.ps
		awk '{printf "0 2 8 0 0 CB [%s,%s] (%.2f,%.2f) (%.2f,%.2f)\n", "'$x'", "'$y'", $1, $2, $3, $4}' $$.d | pstext -R -J -O -K -Xa$xpos -Ya$ypos -N -D0/0.2i >> cartesian.ps
		echo $az | awk '{printf "2 -2 8 0 0 RB @~a@~ = %s\232\n", $1}' | pstext -R -J -O -K -Xa$xpos -Ya$ypos -N -D-0.05i/0.05i -Wwhiteo >> cartesian.ps
		xpos=`gmtmath -Q $xpos 1.9 ADD =`
		Bx=we
	done < pts.$$
	ypos=`gmtmath -Q $ypos 2.25 ADD =`
	By=sn
done < azim.$$
psxy -R -J -O /dev/null >> cartesian.ps
compare -density 100 -metric PSNR cartesian_orig.ps cartesian.ps cartesian_diff.png > log
grep inf log > fail
if [ ! -s fail ]; then
        echo "[FAIL]"
	echo $0 >> ../fail_count.d
else
        echo "[PASS]"
        rm -f fail cartesian_diff.png log
fi
rm -f $$.* *.$$
