# git delete old local branches older than 2 months
!#/bin/bash
set -e

number_of_months=2
date_n_months_ago=`date +"%Y-%m-%d" --date="${number_of_months} months ago"`

echo "removing local branches older than ${date_n_months_ago}";
for k in $(git branch | sed /\*/d); 
do
  last_log=$(git log -1 --after=${date_n_months_ago} --pretty=format:"%h%x09%an%x09%ad%x09%s" --date=short) 
  if [[ -z "${last_log}" ]]; 
  then
    last_date_commit=$(git log -1 --pretty=format:"%h%x09%an%x09%ad%x09%s" --date=short | awk '{print $3}')
    if [[ $k == master* ]] || [[ $k == develop* ]]
    then
      break;
    fi 
    echo "removing local branch: $k ${last_date_commit}"
    # remove the # on the next line to remove branches
    # git branch -d $k
  fi 
done
