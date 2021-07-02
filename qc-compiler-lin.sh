#!/usr/bin/env bash

cd source
echo ""
echo "===================="
echo " compiling FTE CCQC "
echo "===================="
echo ""
./fteqcc-cli-lin -srcfile csprogs.src
echo ""
echo "===================="
echo " compiling FTE SSQC "
echo "===================="
echo ""
./fteqcc-cli-lin -srcfile ssprogs.src
echo ""
echo "===================="
echo "  compiling PSP QC  "
echo "===================="
echo ""
./fteqcc-cli-lin -srcfile pspprogs.src
echo ""
echo "===================="
echo " compiling NX-QS QC "
echo "===================="
echo ""
./fteqcc-cli-lin -srcfile nxprogs.src