#!/bin/bash

[[ ! -d hadd ]] || {
  echo -e "found ./hadd!\nfix the previous attempt and then re-run"
  exit 1
}
echo "generating hadd/allfiles.txt"
mkdir hadd
ls -1 data > hadd/allfiles.txt
sed -i 's/^/data\//' hadd/allfiles.txt
read Nfiles filename < <(wc --lines hadd/allfiles.txt)
[[ "${filename}" == "hadd/allfiles.txt" ]] || {
  echo "something went really wrong somewhere..."
  exit 1
}
echo "${Nfiles} found in hadd/allfiles.txt"

echo "writing splitfiles_X.root"
split -d -n l/$(( Nfiles/50 )) --additional-suffix=.txt hadd/allfiles.txt hadd/splitfiles_
read Nsplitfiles < <(ls hadd/splitfiles_*.txt)

echo "performing first-level merge..."
for file in hadd/splitfiles_*.txt
do {
  rootfilename="${file%.txt}.root"
  echo "hadd ${file} lines into ${rootfilename}..."
  hadd -f0 -O "${rootfilename}" $(cat "${file}") || {
    retval=$?
    echo "hadd returned ${retval} :-("
    exit $retval
  }
}
done
read Nrootfiles < <(ls hadd/splitfiles_*.root)
[[ "${Nsplitfiles}" -eq "${Nrootfiles}" ]] || {
  echo "File counts don't match!"
  echo "Nsplitfiles: ${Nsplitfiles}"
  echo "Nrootfiles: ${Nrootfiles}"
  exit 1
}

echo -e "\nperforming final merge..."
hadd -O allfiles.root hadd/splitfiles_*.root

