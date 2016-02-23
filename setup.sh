if [ -f .git-fix-whitespaces.sh ]
then
    ln -fs ../../.git-fix-whitespaces.sh .git/hooks/pre-commit
else
    echo '\nError: Fix whitespace script not found repository.'
fi
