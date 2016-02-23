#!/bin/sh
# Pre-commit hook for git which removes trailing whitespace, converts tabs to
# spaces and adds a newline to the end of the file if missing. The script does
# not process files that are partially staged. Reason: The `git add` in the last
# line would fully stage a file which is not what the user wants.

if git rev-parse --verify HEAD >/dev/null 2>&1 ; then
   against=HEAD
else
   # Initial commit: diff against an empty tree object
   against=4b825dc642cb6eb9a060e54bf8d69288fbee4904
fi

if [ "$1" == "-f" ]; then
   # Fix all committed files: diff against an empty tree object
   against=4b825dc642cb6eb9a060e54bf8d69288fbee4904
fi

staged_files=`git diff-index --name-status --cached $against | # Find all staged files
              egrep -i '^(A|M)'                              | # Filter only added and modified files
              sed -e 's/^[AM][[:space:]]*//'`                  # Remove leading git info

partially_staged_files=`git status --porcelain --untracked-files=no | # Find all staged files
                        egrep -i '^(A|M)M'                          | # Filter only partially staged files
                        sed -e 's/^[AM]M[[:space:]]*//'`              # Remove leading git info

# Merge staged files and partially staged files
staged_and_partially_staged_files=${staged_files}$'\n'${partially_staged_files}

# Remove all files that are staged *AND* partially staged
# Thus we get only the fully staged files
fully_staged_files=`echo "$staged_and_partially_staged_files" | uniq -u`

# Find the file types we want to process
suffix_matched_files=`echo "$fully_staged_files" |
                        egrep -i '\.(yaml|yml)$' |
                        egrep -v 'vcr_cassettes'`

name_matched_files=`echo "$fully_staged_files" |
                      egrep -i '^(*|\.gitignore)$' |
                      egrep -v 'vcr_cassettes'`

files_to_process=${suffix_matched_files}$'\n'${name_matched_files}
files_to_process=`echo "$files_to_process" | sort | uniq -u`

# Change field separator to newline so that for correctly iterates over lines
IFS=$'\n'

for FILE in $files_to_process ; do
    echo "Fixing whitespace and newline in $FILE" >&2

    # Replace tabs with four spaces
    sed -i $'s/\t/HerewasTAB/g' "$FILE"
    # Strip trailing whitespace
    #sed -i '' -E 's/[[:space:]]*$//' "$FILE"
    sed -i '' -e's/[ \t]*$//' "$FILE"

    # Add newline to the end of the file if missing
    newline='
'
    lastline=$(tail -n 1 ${FILE}; echo x); lastline=${lastline%x}
    [ "${lastline#"${lastline%?}"}" != "$newline" ] && echo >> $FILE

    # Stage all changes
    git add "$FILE"
done
