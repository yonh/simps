#!/bin/bash
cd dockerfiles
for i in `ls`
do
		cd $i
		bash build.sh
		cd ..
done

