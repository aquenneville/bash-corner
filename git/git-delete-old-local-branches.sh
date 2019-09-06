# git delete old local branches older than 3 months
!#/bin/bash
set -e

number_of_months=3
date_n_months_ago=`date +"%Y-%m-%d" --date="${number_of_months} months ago"`

echo "removing local branches older than ${date_n_months_ago}";
for k in $(git branch | sed /\*/d); do
  if [ ! -n "$(git log -1 --after='2019-06-01' $k)" ]; 
  then
    last_date_commit=`git log -1 --pretty=format:"%h%x09%an%x09%ad%x09%s" --date=short | awk '{print $3}'` 
    echo "removing local branch: $k ${last_date_commit}"
    # remove the # on the next line to remove branches
    # git branch -d $k
  fi 
done
